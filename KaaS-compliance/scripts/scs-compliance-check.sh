#!/usr/bin/env bash
# SCS KaaS compliance check for the openEduSuite bare-metal K3s cluster.
# Usage: ./scs-compliance-check.sh [--context <kube-context>]
set -euo pipefail

CONTEXT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --context) CONTEXT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

KUBECTL=(kubectl)
if [[ -n "$CONTEXT" ]]; then KUBECTL+=(--context "$CONTEXT"); fi

pass=0; fail=0; warn=0
ok()   { echo "  [PASS] $*"; pass=$((pass+1)); }
bad()  { echo "  [FAIL] $*"; fail=$((fail+1)); }
note() { echo "  [WARN] $*"; warn=$((warn+1)); }

echo "=== SCS KaaS compliance check ==="
if ! "${KUBECTL[@]}" get nodes >/dev/null 2>&1; then
  echo "Cannot reach cluster. Check kubeconfig/context." >&2
  exit 1
fi

echo "--- SCS-0210: Kubernetes version policy ---"
ver="$("${KUBECTL[@]}" version -o json 2>/dev/null | sed -n 's/.*"gitVersion":"\([^"]*\)".*/\1/p' | head -1)"
if [[ -z "$ver" ]]; then ver="$("${KUBECTL[@]}" version --short 2>/dev/null | awk '/Server/{print $3}')"; fi
echo "  server version: $ver"
if [[ "$ver" == v1.36* ]]; then ok "version in supported window"; else note "version outside expected window ($ver)"; fi

echo "--- SCS-0214: node distribution ---"
nodes="$("${KUBECTL[@]}" get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')"
echo "  node count: $nodes"
if [[ "$nodes" -ge 3 ]]; then ok "at least 3 nodes"; else bad "fewer than 3 nodes"; fi
missing=0
while IFS= read -r n; do
  zone="$("${KUBECTL[@]}" get node "$n" -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}' 2>/dev/null || true)"
  [[ -z "$zone" ]] && { echo "  node $n: missing zone label"; missing=1; }
done < <("${KUBECTL[@]}" get nodes -o name 2>/dev/null | sed 's#node/##')
[[ "$missing" -eq 0 ]] && ok "all nodes have zone labels" || bad "missing zone labels"

echo "--- SCS-0211: default storage class ---"
sc="$("${KUBECTL[@]}" get sc -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{"\n"}{end}' 2>/dev/null | head -1)"
echo "  default storage class: ${sc:-<none>}"
if [[ "$sc" == "ceph-rbd" ]]; then ok "ceph-rbd is default"; else bad "default is not ceph-rbd (${sc:-none})"; fi

echo "--- SCS-0217: pod security standards ---"
ns_count=0
while IFS= read -r ns; do
  enforce="$("${KUBECTL[@]}" get ns "$ns" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)"
  [[ "$enforce" == "baseline" || "$enforce" == "restricted" ]] && ns_count=$((ns_count+1))
done < <("${KUBECTL[@]}" get ns -o name 2>/dev/null | sed 's#namespace/##')
echo "  namespaces with baseline/restricted enforce: $ns_count"
if [[ "$ns_count" -ge 8 ]]; then ok "pod security enforced on >=8 namespaces"; else note "only $ns_count namespaces enforced"; fi

echo "--- SCS-0219: KaaS networking ---"
np="$("${KUBECTL[@]}" get networkpolicy -A --no-headers 2>/dev/null | wc -l | tr -d ' ')"
echo "  NetworkPolicies: $np"
if [[ "$np" -ge 30 ]]; then ok ">=30 NetworkPolicies deployed"; else note "fewer than 30 NetworkPolicies ($np)"; fi

echo "--- SCS-0201: CNCF conformance ---"
echo "  (full conformance run is manual; expected 444/444, 0 failed)"
note "run registry.k8s.io/conformance:v1.36.3 manually and verify 444 passed"

echo "=== SUMMARY ==="
echo "PASS=$pass FAIL=$fail WARN=$warn"
[[ "$fail" -eq 0 ]]
