<!--
SPDX-FileCopyrightText: 2026 SCS Contributors
SPDX-License-Identifier: Apache-2.0
-->

# SCS Compliance Status Report

**Generated:** 2026-08-28 (live verification via `scs-k3s-tunnel-config`)
**Cluster:** scs-k3s (bare-metal K3s — node-1/07/08)
**Method:** Cross-check of documented compliance artifacts against **live cluster state** (`kubectl`) and live node checks (SSH).

---

## 1. Executive Summary

| Track | Status | Verdict |
|-------|--------|---------|
| **SCS KaaS Standards (SCS-0502)** | 6/6 standards PASS (2026-08-23 CNCF conformance 444/444) | ✅ **COMPLIANT** |
| **DevSecOps / SCS-0217 hardening** | Assessment 78/100; **critical P1/P0 gaps still open (live-verified)** | 🟡 **NEEDS WORK** |
| **DSGVO / HDSIG release** | Documentation complete, **cluster NOT released for personal data** | 🔴 **NOT RELEASED** |

**Headline:** SCS standards compliance is solid and continuously monitored. This session (2026-08-28) completed the bulk of the security hardening during a maintenance window: **duplicate default StorageClass fixed**, **Pod Security baseline expanded 8 → 17 namespaces**, **K3s API audit logging ENABLED**, **secrets encryption at rest ENABLED**, and **Phase-2 SSH + CIS kernel hardening applied** on all 3 nodes. Remaining: DSGVO P0 risks + IT operations/DSB sign-off (datenschutz release), optional secrets key rotation, and Phase 3-4 items.

---

## 2. SCS KaaS Standards (verified live 2026-08-28)

| Standard | Doc Status | Live Evidence | Result |
|----------|-----------|---------------|--------|
| SCS-0210 (K8s version) | ✅ | `Server Version: v1.36.3+k3s1` (2026-08-04 build) | ✅ PASS |
| SCS-0214 (Node distribution) | ✅ | `node-1 fip-zone-a`, `node-2 fip-zone-b`, `node-3 fip-zone-c`; 3 nodes | ✅ PASS |
| SCS-0211 (Default SC) | ✅ | **FIXED 2026-08-28**: `ceph-rbd` sole default; `local-path` now `is-default-class=false` | ✅ PASS |
| SCS-0217 (Cluster hardening) | ✅ (doc) | PodSecurity controller active; **enforce=baseline on 17 NS** (was 8); 5 NS deferred (hostNetwork workloads) in audit+warn | 🟡 **PARTIAL → IMPROVED** |
| SCS-0219 (KaaS networking) | ✅ | 40 NetworkPolicies (`kubectl get networkpolicy -A`), NetworkPolicy API available | ✅ PASS |
| SCS-0201 (CNCF conformance) | ✅ | 444/444 documented (2026-08-23) | ✅ PASS |

**Note:** The compliance monitoring dashboard reports `scs_overall_update_readiness = 1` (15/16 checks pass, 1 warning = SCS-0201 seeded).

---

## 3. DevSecOps Hardening (SCS-0217 + best practice) — live status

### 3.1 Still-open critical gaps (live-verified)

| Gap | Doc Risk | Live Check | Status |
|-----|----------|------------|--------|
| **K3s API audit logging** | HIGH (CVSS 8.5) | ✅ **DONE 2026-08-28** — audit.log active, 6 apiserver flags, metric `apiserver_audit_event_total` counting | ✅ **CLOSED** |
| **Secrets encryption at rest** | HIGH (CVSS 7.5) | ✅ **DONE 2026-08-28** — `k3s secrets-encrypt status` → Enabled (AES-CBC); verified no plaintext in etcd db | ✅ **CLOSED** (key rotation optional follow-up) |
| **Pod Security on all namespaces** | MEDIUM (CVSS 6.5) | ✅ **IMPROVED 2026-08-28**: 8 → 17 NS enforce=baseline; 5 NS (default, dovecot-eval, dovecot-wormhole, next-mailserver-test) deferred in audit+warn because they run hostNetwork/hostPath workloads that violate baseline | 🟡 **PARTIALLY CLOSED** |
| Incident response plan | HIGH | ✅ **DONE 2026-08-28** — `INCIDENT-RESPONSE-PLAN.md` created (SEV levels, runbooks, roles/escalation, DSGVO Art.33/34 duties) | ✅ **CLOSED** |
| Central log aggregation (Loki) | MEDIUM | Not deployed | 🟡 **OPEN** |
| Trivy image scanning in CI/CD | MEDIUM | Tool present locally, not integrated | 🟡 **OPEN** |
| Second auth method (OIDC/webhook) | MEDIUM | Not configured | 🟡 **OPEN** |

### 3.2 Controls confirmed live as secure ✅

- Kubelet: anonymous-auth disabled, Webhook authorization, read-only port off (documented/configz)
- UFW active; SSH key auth only, `PermitRootLogin no`
- NetworkPolicies enforced (40 present)
- Default SA restricted (`kubectl auth can-i` → no)
- etcd accessible only via localhost (K3s embedded)

---

## 4. Pod Security Label Coverage (live `kubectl get ns`)

**enforce=baseline (17 — was 8):** `argocd`, `backup`, `cert-manager`, `cronjob-4393`, `home`, `kube-node-lease`, `kube-public`, `llm`, `monitoring`, `nix-builder`, `opendesk-edu`, `opendesk-predictive-agent`, `opendesk-sme`, `opendesk-staff`, `opendesk-students`, `scs-monitoring`, `stalwart-eval`

**enforce=privileged (3):** `logging`, `metallb-system`, `opendesk` (documented system components)

**audit/warn baseline, enforce deferred (5):** `default`, `dovecot-eval`, `dovecot-wormhole`, `next-mailserver-test`, and `kube-system` (privileged audit/warn). These are NOT enforced because they contain `hostNetwork`/`hostPath`/host-debugger workloads that violate baseline (e.g. `node-debugger` in `default`, dovecot/openldap with host networking) — enforcing would block restart/reschedule and break them. Left in non-disruptive audit+warn mode.

---

## 5. StorageClass default deviation — RESOLVED (2026-08-28)

The documented compliance claimed `ceph-rbd` was made default and `local-path` unset. **Live cluster showed otherwise** — both were annotated default:

```
ceph-rbd       DEFAULT=true
local-path     DEFAULT=true     ← deviation (both annotated is-default-class=true)
```

Two storage classes cannot both be the default (violates SCS-0211 single-default; nondeterministic PVC provisioning).

**✅ RESOLVED (2026-08-28):**
```bash
kubectl patch storageclass local-path -p \
  '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
# verified:
kubectl get sc -o custom-columns='SC:.metadata.name,DEFAULT:.metadata.annotations.storageclass\.kubernetes\.io/is-default-class'
# → ceph-rbd true, local-path false
```

---

## 6. DSGVO / HDSIG Datenschutz — release status

**Documentation:** All 6 UMR paper-work docs ✅ (Betriebsmittel, VVT, TOM, DSFA, Betroffenenrechte, Anpassungs-Checkliste).

**Release status:** 🔴 **NOT RELEASED for personal data processing.**

> SCS ist aktuell ein Test-Cluster – NICHT für die Verarbeitung personenbezogener Daten freigegeben!
> REST-Risiko: 🔴 Hoch — 5 kritische P0-Risiken vor Freigabe beheben.
> Freigabe durch IT Management (Cluster Lead) + DSB erforderlich.

### Open P0 risks (target date 2026-08-28 in docs)

| ID | Risk | Owner |
|----|------|-------|
| R-01 | Firewall on mgmt interface (SSH 22 / NRPE 5666 restrict to IT operations nets) | network team |
| R-02 | Backup-Mirror TLS cert CN/IP SAN on mirror-host | Tobias Weiß |
| R-03 | IP pseudonymization / 7-day log retention (BGH C-582/14) | Tobias Weiß |
| R-04 | Icinga2 integration (hosts + 10 K3s service checks) | Tobias Weiß |
| — | Re-assess REST risk to 🟢/🟡 before release | — |

---

## 7. Consolidated Action List (priority)

| # | Priority | Action | Track | Status |
|---|----------|--------|-------|--------|
| 1 | 🔴 P1 | Remove duplicate `default` from `local-path` SC | SCS-0211 | ✅ **DONE 2026-08-28** |
| 2 | 🔴 P1 | Enable K3s API audit logging (P1-AUD-001) | Hardening | ✅ **DONE 2026-08-28** (audit.log active, metric 6453) |
| 3 | 🔴 P1 | Enable secrets encryption at rest (P1-ENC-001) | Hardening | ✅ **DONE 2026-08-28** (Enabled, AES-CBC, verified at rest) — key rotation is optional follow-up |
| 4 | 🔴 P1 | Enforce Pod Security baseline on all namespaces | Hardening | 🟡 **partially DONE** — 8→17 enforced; 5 deferred (hostNetwork workloads) |
| 5 | 🔴 P0 | Remediate DSGVO R-01..R-04 | Datenschutz | 🔴 open |
| 6 | 🔴 P0 | Re-assess REST risk; obtain IT operations + DSB sign-off | Datenschutz | 🔴 open |
| 7 | 🟡 P2 | Loki aggregation, Trivy CI, OIDC | Hardening | 🔴 open |

Automation for #2–4 exists: `docs/operations/scripts/scs-devsecops-harden.sh`.

---

## 8. Remediation Log

### 2026-08-28 (this session — live changes applied)

1. **StorageClass default deviation fixed** — `local-path` set to `is-default-class=false`; `ceph-rbd` is now the sole default. Verified with `kubectl get sc`. (SCS-0211)
2. **Pod Security baseline expansion** — `enforce=baseline` applied to 9 additional namespaces (`home`, `llm`, `nix-builder`, `scs-monitoring`, `opendesk-sme`, `opendesk-edu`, `stalwart-eval`, `kube-node-lease`, `kube-public`); verified no pods broken. Namespaces with `hostNetwork`/`hostPath` workloads (`default` w/ node-debugger, `dovecot-eval`, `dovecot-wormhole`, `next-mailserver-test`) intentionally left in non-disruptive **audit+warn** mode; `kube-system` set to privileged audit/warn. (SCS-0217)
3. **Hardening script SSH fix** — corrected `AllowUsers scs ansible` → `AllowUsers scs dragon demo` in `scs-devsecops-harden.sh`. Live check showed NO `ansible` user on the K3s nodes (ansible runs as `scs`; see `ansible-baremetal-k3s/ansible/inventory.yml` `ansible_user: scs`), and real interactive users are `scs dragon demo`. Running unmodified would have locked out `dragon`/`demo`. (Phase-2 safety)

### 2026-08-28 (maintenance window — 2× K3s restart, SSH/kernel applied)

4. **K3s API audit logging ENABLED** (P1-AUD-001) — audit policy `/etc/rancher/k3s/audit-policy.yaml` created; 6 `--kube-apiserver-arg=audit-*` flags added to `k3s.service` (after `--cluster-cidr`); log dir `/var/lib/rancher/k3s/server/logs/` (0700); K3s restarted. Verified: `audit.log` present and growing (74MB), `apiserver_audit_event_total=6453`. Service file backed up (`k3s.service.bak.*`).
5. **Secrets encryption at rest ENABLED** (P1-ENC-001) — created `/etc/rancher/k3s/config.yaml` with `secrets-encryption: true`; K3s restarted; `sudo k3s secrets-encrypt status` → **Enabled** (AES-CBC aescbckey, hashes match). Verified at rest: wrote test secret with marker, confirmed NO plaintext/base64 marker in `/var/lib/rancher/k3s/server/db/`. API round-trip correct. Test secret cleaned up. (`encryption-config.json` + `encryption-state.json` present.) Note: rotation stage is "start" — optional key rotation (`k3s secrets-encrypt rotate-keys`) is a recommended follow-up, deferred (brief disruption).
6. **SSH hardening APPLIED** (P2-SSH-001) — on all 3 nodes: `PermitRootLogin no`, `PasswordAuthentication no`, `MaxAuthTries 3`, `LoginGraceTime 60`, `AllowUsers scs dragon demo`, `X11Forwarding no`, `AllowAgentForwarding no`, `ClientAliveInterval 300`/`CountMax 2`, `AllowTcpForwarding yes` (tunnels preserved). Restarted `ssh` service (Debian name, NOT `sshd`). Disabled pre-existing `X11Forwarding yes` (line 99) which took first-match precedence. Backups `sshd_config.bak.*`. Verified effective settings via `sshd -T` on all nodes. Connectivity re-verified.
7. **CIS kernel hardening APPLIED** (P2-KER-001) — `/etc/sysctl.d/99-scs-security.conf` on all 3 nodes: `ip_forward=1` (kept for Flannel), rp_filter=1, syncookies=1, kptr_restrict=2, dmesg_restrict=1, ASLR=2, suid_dumpable=0, redirects/source-route off, log_martians=1, TCP keepalive. Values verified live.

### Pre-existing (NOT caused by this work)
- **`opendesk-sme` ArgoCD app Degraded** — all affected pods (`ums-keycloak-0`, `ums-keycloak-extensions-handler`, `ums-ldap-server-primary-0`, `ums-selfservice-listener`) have AGE 2d4h (crashlooping since before today) with missing secrets/configmaps (`opendesk-certificates-tls`, `ox-connector-provisioning-api`, `ums-stack-data-ums-ucr`). Predates maintenance; out of scope for compliance hardening. Flagged for follow-up.

### Deferred (remain open)

- **Secrets-encryption key rotation** — optional hardening; `rotate-keys` causes brief disruption, deferred.
- **DSGVO P0 risks R-01..R-04** + REST re-assessment + IT operations/DSB sign-off — owner Tobias Weiß / network team.
- **Phase 3-4** — incident response plan, Loki aggregation, Trivy CI, OIDC, Falco, kube-bench.

---

*Last updated: 2026-08-28 (live-verified; remediation steps 1–3 applied this session)*
