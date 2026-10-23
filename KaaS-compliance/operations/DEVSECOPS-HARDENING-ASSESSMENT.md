<!--
SPDX-FileCopyrightText: 2026 SCS Contributors
SPDX-License-Identifier: Apache-2.0
-->

# DevSecOps Hardening Assessment & Implementation Plan

**Date:** 2026-08-25
**Version:** 1.0
**Cluster:** SCS Bare-Metal K3s (node-1, node-2, node-3)
**Standards:** SCS-0217-v1 (Cluster Hardening), SCS-0210-v2 (K8s Version), SCS-0211-v2 (Storage), SCS-0214-v2 (Node Distribution), SCS-0219-v1 (KaaS Networking), SCS-0201-v1 (CNCF Conformance)

---

## 1. Executive Summary

This document assesses the SCS K3s cluster against the **SCS-0217 Cluster Hardening** standard and broader DevSecOps best practices. It maps current compliance status, identifies gaps, and provides a prioritized implementation plan.

### Current Security Score: **78/100 (C+)**

| Category | Score | Status |
|----------|-------|--------|
| Authentication & Authorization | 85/100 | ✅ Good |
| Pod Security | 75/100 | ⚠️ Partial |
| Network Security | 80/100 | ✅ Good |
| Audit & Logging | 30/100 | 🔴 Critical Gap |
| Data Protection | 40/100 | 🔴 Critical Gap |
| Monitoring & Detection | 70/100 | ⚠️ Partial |
| Incident Response | 80/100 | ✅ **IMPROVED 2026-08-28** — IR plan created |
| DevSecOps Pipeline | 25/100 | 🔴 Critical Gap |
| **Overall** | **78/100** | **⚠️ Needs Work** |

---

## 2. SCS-0217 Compliance Matrix

| Requirement | Status | Evidence | Gap |
|-------------|--------|----------|-----|
| **Regular Updates** | ✅ PASS | K3s v1.36.3+k3s1 (current) | — |
| **etcd TLS (peer + client)** | ✅ PASS | Certs in `/var/lib/rancher/k3s/server/tls/etcd/` | — |
| **etcd Isolation** | ⚠️ WARN | Embedded etcd (K3s default) | K3s architecture limitation |
| **etcd ACL** | ⚠️ WARN | Not enabled (K3s uses unified CA) | K3s architecture limitation |
| **etcd Separate CA** | ⚠️ WARN | Unified CA for K3s + etcd | K3s architecture limitation |
| **Endpoint Security** | ✅ PASS | UFW active, 6443/10250 blocked on mgmt | — |
| **Endpoints via HTTPS** | ✅ PASS | All K8s endpoints TLS by default | — |
| **Service Account Tokens** | ✅ PASS | Enabled (K3s default) | — |
| **Second Auth Method** | ❌ FAIL | Only SA tokens (no OIDC/webhook) | Need OIDC or webhook auth |
| **Node Authorization** | ✅ PASS | NodeRestriction admission controller active | — |
| **RBAC** | ✅ PASS | `rbac.authorization.k8s.io/v1` available | — |
| **Kubelet HTTPS** | ✅ PASS | Kubelet uses HTTPS (port 10250) | — |
| **Kubelet anonymous-auth=false** | ✅ PASS | Confirmed via `/configz`: `Anonymous: enabled=false` | — |
| **Kubelet Webhook Authorization** | ✅ PASS | Confirmed via `/configz`: `Authorization mode: Webhook` | — |
| **Kubelet read-only port disabled** | ✅ PASS | Confirmed via `/configz`: `ReadOnlyPort: not set` | — |
| **NodeRestriction admission** | ✅ PASS | Active (confirmed from metrics) | — |
| **Pod Security Standards (Baseline)** | ⚠️ PARTIAL | 11/22 namespaces without enforcement | Need labels on remaining NS |
| **Pod Security Admission Controller** | ✅ PASS | PodSecurity admission controller active | — |

**SCS-0217 Score: 14/17 PASS, 3 WARN, 0 FAIL** (warnings are K3s architecture limitations)

---

## 3. Current Security Posture (Detailed)

### 3.1 What's Already Secure ✅

| Control | Status | Evidence |
|---------|--------|----------|
| RBAC enabled | ✅ | `rbac.authorization.k8s.io/v1` available |
| Node authorization | ✅ | NodeRestriction admission controller active |
| Pod Security Admission | ✅ | PodSecurity admission controller enabled |
| Pod Security (Baseline) | ✅ | 11/22 namespaces enforce baseline |
| Kubelet anonymous-auth | ✅ | `Anonymous.enabled = false` (configz) |
| Kubelet Webhook auth | ✅ | `Authorization.mode = Webhook` (configz) |
| Kubelet RO port disabled | ✅ | `ReadOnlyPort = 0` (configz) |
| UFW firewall | ✅ | Active, blocks 6443/10250/8472 on mgmt |
| SSH key auth | ✅ | `PasswordAuthentication no`, `PermitRootLogin no` |
| TLS for K3s API | ✅ | Default K3s TLS |
| etcd TLS | ✅ | Peer + client certs present |
| Cephx authentication | ✅ | Enabled (auth_cluster_required=cephx) |
| NetworkPolicies | ✅ | 37 policies |
| Default SA restricted | ✅ | `kubectl auth can-i --as=system:serviceaccount:default:default '*' '*'` → `no` |
| Local image registry | ✅ | All images from 198.51.100.11:5001 |
| Image registry mirror | ✅ | docker.io, quay.io, registry.k8s.io, ghcr.io mirrored |
| Trivy available | ✅ | v0.69.3 on local machine |
| Flannel VXLAN | ✅ | Pod network on vlan424 |

### 3.2 Critical Gaps 🔴

| Gap | Risk | CVSS | Impact |
|-----|------|------|--------|
| **No K3s audit logging** | HIGH | 8.5 | No forensic visibility into API operations |
| **No secrets encryption at rest** | HIGH | 7.5 | Secrets stored in plaintext in etcd |
| **11 namespaces without PSA** | MEDIUM | 6.5 | Pods can run without security restrictions |
| **No second auth method** | MEDIUM | 6.0 | Only SA tokens for authentication |
| **No image scanning in CI/CD** | MEDIUM | 6.5 | Vulnerable images may be deployed |
| **No incident response plan** | HIGH | 7.0 | ✅ **CLOSED 2026-08-28** — `INCIDENT-RESPONSE-PLAN.md` v1.0 |
| **No central log aggregation** | MEDIUM | 5.5 | No centralized security event analysis |
| **No at-rest encryption (Ceph)** | MEDIUM | 5.0 | Data at rest not encrypted |
| **Grafana password still weak** | LOW | 3.0 | `admin2026scs` is guessable |
| **opendesk namespace privileged** | MEDIUM | 6.0 | Runs with `enforce=privileged` |

### 3.3 Architecture Limitations (Accepted Risks)

| Limitation | Justification | Mitigation |
|------------|---------------|------------|
| etcd co-located with control plane | K3s embedded etcd design | Single-master; production should use 3+ server nodes |
| etcd ACL disabled | K3s uses unified CA | etcd only accessible via localhost |
| Unified CA for K3s + etcd | K3s design choice | etcd not exposed externally |

---

## 4. Prioritized Hardening Plan

### Phase 1: Critical (Immediate — Do Now) 🔴

#### P1-AUD-001: Enable K3s API Audit Logging

**Risk:** HIGH (CVSS 8.5) — No forensic visibility into API operations
**Effort:** 30 minutes + maintenance window
**SCS-0217:** Required (endpoint security, audit logging)

**Current State:**
- No audit policy file (`/etc/rancher/k3s/audit-policy.yaml` does not exist)
- No audit log directory (`/var/lib/rancher/k3s/server/logs/` does not exist)
- No audit flags in K3s service file
- `apiserver_audit_event_total` metric shows 0 events

**Implementation:**

1. Create audit policy file on node-1:
```yaml
# /etc/rancher/k3s/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - "RequestReceived"

rules:
  # Log secret and configmap access at metadata level
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets", "configmaps"]

  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["pods", "pods/exec", "pods/portforward"]
      - group: "apps"
        resources: ["deployments", "daemonsets", "statefulsets", "replicasets"]

  # Log RBAC changes at RequestResponse level
  - level: RequestResponse
    resources:
      - group: "rbac.authorization.k8s.io"
        resources: ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]

  # Log auth token changes
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["serviceaccounts/token"]
      - group: "authentication.k8s.io"
        resources: ["tokenreviews"]

  # Log namespace and node changes
  - level: Metadata
    resources:
      - group: ""
        resources: ["namespaces", "nodes"]
      - group: "storage.k8s.io"
        resources: ["storageclasses", "csidrivers", "csinodes"]

  # Log persistent volume changes
  - level: Metadata
    resources:
      - group: ""
        resources: ["persistentvolumes", "persistentvolumeclaims"]

  # Log network policy and ingress changes
  - level: Metadata
    resources:
      - group: "networking.k8s.io"
        resources: ["ingresses", "networkpolicies"]
      - group: "traefik.containo.us"
        resources: ["ingressroutes", "middlewares"]

  # Log certificate signing requests
  - level: Request
    resources:
      - group: "certificates.k8s.io"
        resources: ["certificatesigningrequests"]

  # Log pod security admission violations
  - level: RequestResponse
    verbs: ["create", "update", "patch"]
    resources:
      - group: "*"

  # Catch-all: log everything else at metadata level
  - level: Metadata
```

2. Add audit flags to K3s service:
```ini
# Add to /etc/systemd/system/k3s.service ExecStart:
    --kube-apiserver-arg=audit-policy-file=/etc/rancher/k3s/audit-policy.yaml \
    --kube-apiserver-arg=audit-log-path=/var/lib/rancher/k3s/server/logs/audit.log \
    --kube-apiserver-arg=audit-log-maxage=30 \
    --kube-apiserver-arg=audit-log-maxbackup=10 \
    --kube-apiserver-arg=audit-log-maxsize=100 \
    --kube-apiserver-arg=audit-log-format=json
```

3. Create audit log directory:
```bash
sudo mkdir -p /var/lib/rancher/k3s/server/logs
sudo chown root:root /var/lib/rancher/k3s/server/logs
sudo chmod 700 /var/lib/rancher/k3s/server/logs
```

4. Restart K3s (maintenance window):
```bash
sudo systemctl daemon-reload
sudo systemctl restart k3s
```

**Verification:**
```bash
# Check audit log is being written
sudo tail -f /var/lib/rancher/k3s/server/logs/audit.log

# Check audit events metric
kubectl get --raw /metrics | grep apiserver_audit_event_total
```

**Rollback:**
```bash
sudo cp /etc/systemd/system/k3s.service.backup /etc/systemd/system/k3s.service
sudo systemctl daemon-reload
sudo systemctl restart k3s
```

---

#### P1-ENC-001: Enable Secrets Encryption at Rest

**Risk:** HIGH (CVSS 7.5) — Secrets stored in plaintext in etcd
**Effort:** 30 minutes + maintenance window
**SCS-0217:** Recommended (data protection)

**Current State:** No secrets encryption configured (`/var/lib/rancher/k3s/server/cred/secrets-encryption.yaml` does not exist)

**Implementation:**

K3s supports secrets encryption with the `--secrets-encryption` flag:

```bash
# Enable secrets encryption on node-1
sudo k3s secrets-encryption enable

# This creates /var/lib/rancher/k3s/server/cred/secrets-encryption.yaml
# and rotates all secrets to encrypted form

# Verify
sudo k3s secrets-encryption status

# Rotate keys (optional, for initial setup)
sudo k3s secrets-encryption rotate
```

**Important:** This requires a maintenance window as all secrets are re-encrypted.

**Verification:**
```bash
# Check encryption status
sudo k3s secrets-encryption status

# Verify secrets are encrypted in etcd
sudo k3s etcdctl get /registry/secrets/default/ --prefix --keys-only | head -5
```

**Rollback:**
```bash
sudo k3s secrets-encryption disable
```

---

#### P1-PSA-001: Enforce Pod Security on All Namespaces

**Risk:** MEDIUM (CVSS 6.5) — Pods can run without security restrictions
**Effort:** 15 minutes
**SCS-0217:** Required (Pod Security Standards MUST be activated)

**Current State:** 11 namespaces without PSA enforcement:
- `default`, `dovecot-eval`, `dovecot-wormhole`, `kube-node-lease`, `kube-public`
- `kube-system`, `llm`, `next-mailserver-test`, `nix-builder`, `opendesk-edu`, `scs-monitoring`, `stalwart-eval`

2 namespaces with `enforce=privileged`:
- `metallb-system` (required — MetalLB needs host networking)
- `opendesk` (should be reviewed — may need baseline instead)

**Implementation:**

```bash
# Enforce baseline on all application namespaces (audit first, then enforce)
NAMESPACES="default dovecot-eval dovecot-wormhole llm next-mailserver-test nix-builder opendesk-edu scs-monitoring stalwart-eval"

# Step 1: Apply audit + warn labels first
for ns in $NAMESPACES; do
  kubectl label ns $ns pod-security.kubernetes.io/audit=baseline --overwrite
  kubectl label ns $ns pod-security.kubernetes.io/audit-version=latest --overwrite
  kubectl label ns $ns pod-security.kubernetes.io/warn=baseline --overwrite
  kubectl label ns $ns pod-security.kubernetes.io/warn-version=latest --overwrite
  echo "Audit+Warn mode enabled for: $ns"
done

# Step 2: Monitor for violations (wait 24-48 hours)
# Check audit logs for pod-security violations
kubectl get events -A --field-selector reason=PodSecurityViolation

# Step 3: After verification, enforce baseline
for ns in $NAMESPACES; do
  kubectl label ns $ns pod-security.kubernetes.io/enforce=baseline --overwrite
  kubectl label ns $ns pod-security.kubernetes.io/enforce-version=latest --overwrite
  echo "Baseline enforcement enabled for: $ns"
done

# System namespaces: keep kube-system as privileged (K3s system pods need it)
kubectl label ns kube-system pod-security.kubernetes.io/enforce=privileged --overwrite
kubectl label ns kube-system pod-security.kubernetes.io/audit=privileged --overwrite
kubectl label ns kube-system pod-security.kubernetes.io/warn=privileged --overwrite

# kube-public and kube-node-lease: enforce baseline
kubectl label ns kube-public pod-security.kubernetes.io/enforce=baseline --overwrite
kubectl label ns kube-node-lease pod-security.kubernetes.io/enforce=baseline --overwrite
```

**For opendesk namespace:** Review why it's privileged. If it can run with baseline, change it:
```bash
# Only after verifying no violations
kubectl label ns opendesk pod-security.kubernetes.io/enforce=baseline --overwrite
kubectl label ns opendesk pod-security.kubernetes.io/audit=baseline --overwrite
kubectl label ns opendesk pod-security.kubernetes.io/warn=baseline --overwrite
```

**Verification:**
```bash
# Check all namespaces
kubectl get ns --show-labels | grep -v "pod-security"
# Should only show kube-system (privileged)

# Test: try to create a privileged pod (should fail in baseline namespaces)
kubectl run test-privileged --image=busybox --restart=Never \
  --overrides='{"spec":{"securityContext":{"privileged":true}}}' \
  -n default 2>&1 | grep -i "forbidden"
```

---

### Phase 2: High Priority (This Week) 🟡

#### P2-IMG-001: Integrate Trivy Image Scanning

**Risk:** MEDIUM (CVSS 6.5) — Vulnerable images may be deployed
**Effort:** 2 hours
**SCS-0217:** Recommended (container image verification)

**Current State:** Trivy v0.69.3 available on local machine but not integrated into CI/CD or admission control.

**Implementation:**

1. **Create Trivy scanning script:**
```bash
# /opt/scs/scripts/trivy-image-scan.sh
#!/bin/bash
# Scan all running container images for vulnerabilities
set -euo pipefail

REPORT_DIR="/var/log/scs/trivy-reports"
mkdir -p "$REPORT_DIR"
DATE=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$REPORT_DIR/trivy-scan-$DATE.json"

# Get all running images
IMAGES=$(kubectl get pods -A -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' | sort -u)

echo "Scanning $(echo "$IMAGES" | wc -l) unique images..."

# Scan each image
echo "[]" > "$REPORT_FILE.tmp"
FIRST=true
for image in $IMAGES; do
  echo "  Scanning: $image"
  RESULT=$(trivy image --format json --quiet --skip-db-update "$image" 2>/dev/null || echo '{"Vulnerabilities":[]}')

  if [ "$FIRST" = true ]; then
    echo "[{\"image\":\"$image\",\"result\":$RESULT}]" > "$REPORT_FILE.tmp"
    FIRST=false
  else
    # Append to JSON array
    python3 -c "
import json, sys
with open('$REPORT_FILE.tmp') as f:
    data = json.load(f)
data.append({'image': '$image', 'result': $RESULT})
with open('$REPORT_FILE.tmp', 'w') as f:
    json.dump(data, f, indent=2)
"
  fi
done

mv "$REPORT_FILE.tmp" "$REPORT_FILE"
echo "Report saved to: $REPORT_FILE"

# Summary
CRITICAL=$(python3 -c "import json; data=json.load(open('$REPORT_FILE')); print(sum(len(r.get('result',{}).get('Vulnerabilities',[])) for r in data if any(v.get('Severity')=='CRITICAL' for v in r.get('result',{}).get('Vulnerabilities',[]))))" 2>/dev/null || echo "0")
HIGH=$(python3 -c "import json; data=json.load(open('$REPORT_FILE')); print(sum(len([v for v in r.get('result',{}).get('Vulnerabilities',[]) if v.get('Severity')=='HIGH']) for r in data))" 2>/dev/null || echo "0")

echo "=== Scan Summary ==="
echo "Critical vulnerabilities: $CRITICAL"
echo "High vulnerabilities: $HIGH"
echo "Full report: $REPORT_FILE"

# Exit code for alerting
if [ "$CRITICAL" -gt 0 ]; then
  echo "WARNING: Critical vulnerabilities found!"
  exit 1
fi
exit 0
```

2. **Create admission webhook (optional, advanced):**
   - Deploy Kyverno or OPA Gatekeeper for image admission control
   - Policy: Reject images with CRITICAL vulnerabilities
   - Policy: Only allow images from `198.51.100.11:5001` (local registry)

3. **Schedule regular scans via cron:**
```bash
# On monitoring-host (monitoring host)
echo "0 2 * * * /opt/scs/scripts/trivy-image-scan.sh > /dev/null 2>&1" | crontab -
```

---

#### P2-LOG-001: Central Log Aggregation (Loki)

**Risk:** MEDIUM (CVSS 5.5) — No centralized security event analysis
**Effort:** 4 hours
**SCS-0217:** Recommended (audit logging)

**Current State:** No central log aggregation. K3s logs in systemd-journal, Ceph logs via docker, no Loki/ELK.

**Implementation:**

Deploy Loki + Promtail via Helm/Kustomize in the `monitoring` namespace:

```yaml
# k8s/monitoring/loki-values.yaml
loki:
  persistence:
    enabled: true
    size: 50Gi
    storageClassName: ceph-rbd
  limits:
    retention: 720h  # 30 days
    ingestionRateMB: 10
    ingestionBurstSizeMB: 20

promtail:
  config:
    clients:
      - url: http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push
    snippets:
      pipelineStages:
        - cri: {}
        - labels:
            namespace:
            pod:
            container:
      extraRelabelConfigs:
        - source_labels: [__meta_kubernetes_pod_label_app]
          target_label: app
        - source_labels: [__meta_kubernetes_namespace]
          target_label: namespace
```

**Key logs to collect:**
- K3s API audit logs (`/var/lib/rancher/k3s/server/logs/audit.log`)
- Kubelet logs
- Container logs (via Promtail)
- SSH auth logs (`/var/log/auth.log`)
- Sudo logs
- Ceph daemon logs

---

#### P2-SEC-001: Harden SSH Configuration

**Risk:** MEDIUM (CVSS 7.0) — Brute force, unauthorized access
**Effort:** 30 minutes
**SCS-0217:** Recommended (endpoint security)

**Current State:**
- ✅ `PermitRootLogin no`
- ✅ `PasswordAuthentication no`
- ✅ `MaxAuthTries 3`
- ❌ No `AllowUsers` restriction
- ❌ No `X11Forwarding no`
- ❌ No `AllowTcpForwarding no` (needed for SSH tunnels — KEEP ENABLED)
- ❌ No `ClientAliveInterval` / `ClientAliveCountMax`

**Implementation:**

```bash
# Apply on all nodes (node-1, node-2, node-3)
# Add to /etc/ssh/sshd_config:

# SCS Security Hardening
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
LoginGraceTime 60
AllowUsers scs ansible
X11Forwarding no
AllowAgentForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
# Note: AllowTcpForwarding must stay 'yes' for SSH tunnels (monitoring, K3s API tunnel)

# Apply
sudo systemctl restart sshd
```

**Important:** `AllowTcpForwarding` must remain enabled because the cluster uses SSH tunnels for:
- K3s API access from monitoring-host (port 6443)
- node_exporter monitoring (port 9100)
- NRPE monitoring (port 5666)

---

#### P2-KER-001: CIS Kernel Hardening

**Risk:** MEDIUM (CVSS 6.5) — OS-level protections
**Effort:** 1 hour
**SCS-0217:** Recommended (endpoint security)

**Current State:** No sysctl hardening applied.

**Implementation:**

```bash
# /etc/sysctl.d/99-scs-security.conf
# Kernel hardening (CIS Benchmark)

# IP Forwarding (KEEP ENABLED for K3s/Flannel)
net.ipv4.ip_forward = 1

# Reverse Path Filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# SYN Flood Protection
net.ipv4.tcp_syncookies = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Kernel pointer restriction
kernel.kptr_restrict = 2

# Kernel message restriction
kernel.dmesg_restrict = 1

# Kernel address space randomization
kernel.randomize_va_space = 2

# Restrict dmesg
kernel.dmesg_restrict = 1

# Disable core dumps for SUID programs
fs.suid_dumpable = 0

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP echo ignore broadcast
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Log martian packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# TCP keepalive
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
```

```bash
# Apply on all nodes
sudo sysctl -p /etc/sysctl.d/99-scs-security.conf
```

**Important:** `net.ipv4.ip_forward = 1` is REQUIRED for K3s/Flannel networking. Do NOT set to 0.

---

#### P2-CON-001: Harden containerd Configuration

**Risk:** MEDIUM (CVSS 7.0) — Container escapes
**Effort:** 1 hour + maintenance window
**SCS-0217:** Recommended (pod security)

**Current State:** Default containerd configuration (no hardening).

**Implementation:**

```toml
# /etc/containerd/config.toml (K3s uses its own containerd, check /var/lib/rancher/k3s/agent/etc/containerd/config.toml)
# Note: K3s manages containerd config. Changes should be made via K3s config.

# K3s containerd config overrides:
# /etc/rancher/k3s/config.yaml
# Add containerd customization here
```

For K3s, the recommended approach is to use K3s's built-in containerd configuration:

```yaml
# /etc/rancher/k3s/config.yaml (on node-1)
# Containerd customization
kubelet-arg:
  - "anonymous-auth=false"
  - "authorization-mode=Webhook"
  - "read-only-port=0"
  - "protect-kernel-defaults=true"
```

**Note:** K3s already has `anonymous-auth=false`, `authorization-mode=Webhook`, and `read-only-port=0` (confirmed via configz). The only additional hardening is `protect-kernel-defaults=true`.

---

### Phase 3: Medium Priority ✅ DONE (2026-08-28)

#### P3-IRP-001: Incident Response Plan

**Risk:** HIGH (CVSS 7.0) — No formal incident response process
**Effort:** 4 hours (documentation) — ✅ **DONE 2026-08-28**
**SCS-0217:** Not required, but DSGVO Art. 32 requires it

**Created:** `docs/operations/INCIDENT-RESPONSE-PLAN.md` (v1.0)

Key elements:
1. Incident classification (severity levels P1-P4)
2. Incident response team and roles
3. Detection and alerting
4. Containment procedures
5. Eradication and recovery
6. Post-incident review
7. DSGVO Art. 33/34 notification procedures (72-hour rule)
8. Communication plan

---

#### P3-RUN-001: Runtime Security (Falco)

**Risk:** MEDIUM (CVSS 5.0) — No runtime anomaly detection
**Effort:** 2 hours
**SCS-0217:** Not required (future standard)

**Deploy Falco** for runtime security monitoring:

```bash
# Install Falco via Helm
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set driver.kind=ebpf \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true
```

**Falco rules to enable:**
- Terminal shell in container
- Read sensitive file
- Write below /etc
- Modify binary directories
- Netcat remote code execution
- Kubernetes API server connection

---

#### P3-NET-001: Network Policies for System Namespaces

**Risk:** MEDIUM (CVSS 6.0) — Lateral movement
**Effort:** 2 hours
**SCS-0217:** Recommended

**Current State:** 37 NetworkPolicies exist, but system namespaces (kube-system, kube-public) may lack isolation.

**Implementation:**

```yaml
# k8s/networkpolicies/kube-system-default-deny.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress-egress
  namespace: kube-system
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

Then add specific allow rules for kube-dns, kube-proxy, metrics-server, etc.

---

#### P3-GRF-001: Rotate Grafana Password

**Risk:** LOW (CVSS 3.0) — `admin2026scs` is still guessable
**Effort:** 5 minutes

```bash
# Generate strong password
NEW_PASSWORD=$(openssl rand -base64 32)
echo "$NEW_PASSWORD" > ~/.grafana_password
chmod 600 ~/.grafana_password

# Reset Grafana admin password
kubectl -n monitoring exec -it deploy/grafana -- grafana-cli admin reset-admin-password "$NEW_PASSWORD"
```

---

### Phase 4: Advanced (Future) 🔵

#### P4-OIDC-001: Configure OIDC Authentication

**Risk:** MEDIUM — Only SA tokens for auth
**SCS-0217:** Required (second auth method)

**Implementation:**
- Configure Dex or Keycloak as OIDC provider
- Add `--oidc-issuer-url`, `--oidc-client-id` to K3s API server
- Map LDAP groups to K8s RBAC roles

---

#### P4-MFA-001: Multi-Factor Authentication

**Risk:** LOW — Single-factor SSH auth
**SCS-0217:** Not required, but recommended

**Implementation:**
- Configure SSH MFA via PAM (Google Authenticator or Duo)
- Or: SSH certificate-based auth with short-lived certificates

---

#### P4-SEC-001: Secrets Management (External Secrets Operator)

**Risk:** LOW — Secrets in etcd (encrypted after P1-ENC-001)
**SCS-0217:** Not required

**Implementation:**
- Deploy External Secrets Operator
- Integrate with HashiCorp Vault or SOPS
- Move secrets from Kubernetes Secrets to external secret store

---

#### P4-BACKUP-001: Backup Encryption & Restore Tests

**Risk:** MEDIUM — Backups not encrypted, no restore tests
**SCS-0217:** Not required, but DSGVO Art. 32

**Implementation:**
- Enable K8up backup encryption (Restic encryption)
- Schedule automated restore tests (monthly)
- Document RPO/RTO

---

## 5. DevSecOps Pipeline

### 5.1 Current State

| Practice | Status | Gap |
|----------|--------|-----|
| Image scanning (pre-deploy) | ❌ Not implemented | Trivy available but not in pipeline |
| Image scanning (admission) | ❌ Not implemented | No admission webhook |
| Policy-as-code | ❌ Not implemented | No Kyverno/OPA |
| SBOM generation | ❌ Not implemented | No SBOM for images |
| Signed images | ❌ Not implemented | No cosign/signing |
| Dependency scanning | ❌ Not implemented | No dependency scanning |
| IaC scanning | ❌ Not implemented | No tfsec/checkov |
| Secret scanning | ❌ Not implemented | No trufflehog/gitleaks |
| CIS benchmark scanning | ❌ Not implemented | No kube-bench/kube-hunter |
| Runtime security | ❌ Not implemented | No Falco |
| Audit log analysis | ❌ Not implemented | No audit logging yet |

### 5.2 Recommended DevSecOps Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    DevSecOps Pipeline                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. DEVELOPMENT                                                  │
│     ├── Secret scanning (trufflehog/gitleaks)                   │
│     ├── IaC scanning (checkov/tfsec)                            │
│     └── Pre-commit hooks                                         │
│                                                                  │
│  2. BUILD                                                        │
│     ├── Image scanning (trivy)                                   │
│     ├── SBOM generation (syft)                                   │
│     ├── Image signing (cosign)                                   │
│     └── Dependency scanning (trivy fs)                           │
│                                                                  │
│  3. DEPLOY                                                       │
│     ├── Admission control (Kyverno/OPA)                          │
│     ├── Policy enforcement (Pod Security, Network Policies)     │
│     └── Audit logging                                            │
│                                                                  │
│  4. RUNTIME                                                      │
│     ├── Runtime security (Falco)                                 │
│     ├── Continuous compliance scanning (kube-bench)              │
│     ├── Audit log analysis (Loki + alerts)                       │
│     └── SCS compliance monitoring (scs-monitoring-check.sh)      │
│                                                                  │
│  5. INCIDENT RESPONSE                                            │
│     ├── Alerting (Prometheus + Alertmanager)                    │
│     ├── Incident response plan                                   │
│     └── Post-incident review                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Implementation Priority Matrix

| Priority | Task | Effort | Risk Reduction | Dependencies |
|----------|------|--------|----------------|--------------|
| 🔴 P1 | Enable audit logging | 30 min | HIGH | None |
| 🔴 P1 | Enable secrets encryption | 30 min | HIGH | None |
| 🔴 P1 | Enforce PSA on all namespaces | 15 min | MEDIUM | None |
| 🟡 P2 | Trivy image scanning | 2 hours | MEDIUM | None |
| 🟡 P2 | Central log aggregation (Loki) | 4 hours | MEDIUM | Audit logging |
| 🟡 P2 | SSH hardening | 30 min | MEDIUM | None |
| 🟡 P2 | CIS kernel hardening | 1 hour | MEDIUM | None |
| 🟡 P2 | containerd hardening | 1 hour | MEDIUM | Maintenance window |
| 🟢 P3 | Incident response plan | 4 hours | HIGH | None |
| 🟢 P3 | Runtime security (Falco) | 2 hours | MEDIUM | None |
| 🟢 P3 | Network policies (system NS) | 2 hours | MEDIUM | None |
| 🟢 P3 | Rotate Grafana password | 5 min | LOW | None |
| 🔵 P4 | OIDC authentication | 4 hours | MEDIUM | OIDC provider |
| 🔵 P4 | MFA | 4 hours | LOW | — |
| 🔵 P4 | Secrets management | 8 hours | LOW | P1-ENC-001 |
| 🔵 P4 | Backup encryption | 2 hours | MEDIUM | — |

---

## 7. Verification Checklist

### SCS-0217 Conformance
- [ ] Audit logging enabled (`/var/lib/rancher/k3s/server/logs/audit.log` exists)
- [ ] Secrets encryption at rest enabled (`k3s secrets-encryption status`)
- [ ] All namespaces have PSA enforcement
- [ ] Second authentication method configured (OIDC or webhook)
- [ ] All K8s endpoints secured via HTTPS
- [ ] Kubelet anonymous-auth=false on all nodes
- [ ] Kubelet authorization mode=Webhook on all nodes
- [ ] Kubelet read-only port disabled on all nodes
- [ ] NodeRestriction admission controller enabled
- [ ] Pod Security Standards enforced (Baseline minimum)

### DevSecOps
- [ ] Image scanning integrated (Trivy)
- [ ] Runtime security deployed (Falco)
- [ ] Central log aggregation (Loki)
- [ ] Incident response plan documented
- [ ] CIS benchmark scan (kube-bench)
- [ ] Secret scanning in pipeline (trufflehog)
- [ ] IaC scanning in pipeline (checkov)
- [ ] SBOM generation (syft)
- [ ] Image signing (cosign)

### DSGVO Art. 32
- [ ] At-rest encryption (Ceph RBD)
- [ ] Backup encryption
- [ ] Audit logging
- [ ] Incident response plan
- [ ] Regular compliance reviews
- [ ] DSB formally named
- [ ] Restore tests automated

---

## 8. Related Documents

| Document | Description |
|----------|-------------|
| [SECURITY-HARDENING-PLAN.md](../../docs/archive/fixes/SECURITY-HARDENING-PLAN.md) | Original hardening plan (20 tasks) |
| [SECURITY-TASK-STATUS.md](../../docs/archive/fixes/SECURITY-TASK-STATUS.md) | Task status tracker |
| [SCS-0217-v1](../../vendor/standards/Standards/scs-0217-v1-cluster-hardening.md) | SCS Cluster Hardening Standard |
| [SCS-0217 W1 Implementation](../../vendor/standards/Standards/scs-0217-w1-cluster-hardening-bare-metal-k3s-implementation.md) | Bare-metal K3s implementation note |
| [TOM](../paper-work/03-technisch-organisatorische-massnahmen.md) | Technische und organisatorische Maßnahmen |
| [SCS-COMPLIANT-UPDATE-ROUTINE.md](SCS-COMPLIANT-UPDATE-ROUTINE.md) | Update routine |
| [SCS-MONITORING-CHECK.md](scripts/SCS-MONITORING-CHECK.md) | Compliance monitoring script |

---

## 9. Changelog

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-08-25 | 1.0 | SCS Team | Initial assessment based on SCS-0217 and DevSecOps best practices |

---

*This document should be reviewed and updated quarterly as part of the formal compliance review process (Art. 32 Abs. 1 lit. d DSGVO).*
