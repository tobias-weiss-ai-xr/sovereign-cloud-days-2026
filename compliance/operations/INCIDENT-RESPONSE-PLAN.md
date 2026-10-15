# SCS Incident Response Plan

**Scope:** SCS Bare-Metal K3s cluster — node-1 (control-plane), node-2/08 (workers), Ceph storage, K8up backups
**Version:** 1.0 · **Status:** ✅ ACTIVE (2026-08-28) · **Owner:** Tobias Weiß (K3s-Administrator/Verantwortlicher)
**References:** [TOMs §4 Verantwortlichkeiten](../paper-work/03-technisch-organisatorische-massnahmen.md), [DSFA M-10](../paper-work/04-datenschutz-folgenabschaetzung.md), [Compliance Status Report](../references/COMPLIANCE-STATUS-REPORT.md), [Update- & Rollback-Routine](SCS-COMPLIANT-UPDATE-ROUTINE.md), [DevSecOps Assessment](DEVSECOPS-HARDENING-ASSESSMENT.md)

---

## 1. Purpose

Define **who does what, when, and how** when an incident affects the SCS cluster. Covers technical containment/recovery **and** legal/DSGVO notification duties. This plan closes gap *"Incident response plan — HIGH, OPEN"* (SCS-0217 / DSFA M-10).

---

## 2. Severity Levels

| Level | Name | Criteria | Example | Response window |
|-------|------|----------|---------|-----------------|
| **SEV-4** | Noise | No impact; informational | Failed probe, disk warning | next business day |
| **SEV-3** | Minor | Single component degraded, cluster usable | 1 worker node down, pod crashloops | 4 h |
| **SEV-2** | Major | Core functionality degraded / multi-component | API server slow, Ceph degraded, DoS | 1 h |
| **SEV-1** | Critical | Cluster or data unavailable / suspected breach | etcd data loss, ransomware, confirmed intrusion | **immediately**, 24/7 |
| **SEV-0** | Data breach | Personal data lost / accessed by unauthorised party (confirmed) | Exfiltration of user mailboxes, crypto compromise | **immediately** + **72 h DSGVO Art. 33** |

---

## 3. Roles & Escalation (from TOMs §4)

| Role | Person / Team | Duties in IR | Contact |
|------|---------------|--------------|---------|
| **Incident Commander (IC)** | Tobias Weiß (Verantwortlicher) | Leads response, decides SEV level, containment, comms | [E-Mail] — primary |
| **K3s-Administrator** | Tobias Weiß | K3s/ArgoCD/NetPol recovery, API/etcd forensics | [E-Mail] |
| **Ceph-Administrator** | Tobias Weiß | Storage health, data integrity, snapshot restore | [E-Mail] |
| **Backup-Administrator** | Tobias Weiß | K8up/restic restore, backup-mirror integrity | [E-Mail] |
| **Monitoring-Administrator** | Tobias Weiß | Grafana/Prometheus/Alertmanager, NRPE/Icinga2 | [E-Mail] |
| **IT operations** | Cluster Lead | Infrastructure / network / University IT escalation | via IT operations ticket |
| **DSB (Datenschutzbeauftragter)** | ⚠️ not formally appointed | DSGVO notification, data-subject comms | dpo@example.edu |

> **DSB gap:** DSFA M-09 (appoint DSB) remains open. Until appointed, IT operations + dpo@example.edu are the notification path.

---

## 4. Detection Sources

- **Prometheus/Grafana** (`monitoring` ns, ingress-admin) — node/pod/alert rules
- **K3s API audit log** — `/var/lib/rancher/k3s/server/logs/audit.log` on control-plane (enabled 2026-08-28; JSON format; rotated at 100MB × 10 backups, 30d retention; `apiserver_audit_event_total` metric)
- **Detected volume:** audit rotates ~100 MB / ~15 min (~400 MB/h) at current API activity — disk stays bounded by `maxbackup=10`, but this implies high API churn; investigate if it grows. Watch `/` disk on node-1 (`df -h`, `audit-*.log` count).
- **systemd-journal** — `journalctl -u k3s`, `journalctl -u k3s-agent`, `journalctl -u ssh`
- **NRPE/Icinga2** — 10 checks on all 3 nodes, alert chain PENDING (Icinga2 definitions not configured)
- **Mirror scripts/logs** — backup-mirror TLS logs, rclone/restic job logs (K8up)
- **Ceph** — `ceph -s` (HEALTH_OK vs WARN/ERR), `ceph health detail`

---

## 5. Runbook — by scenario

### 5.1 Node down (SEV-3, escalate SEV-2 if Ceph OSD on it)
1. `kubectl get nodes` — confirm; `ssh scs@<node>` (fallback: IPMI KVM).
2. Check `journalctl -u k3s-agent -n 200`, `load`, disk (`df -h`, `nvme`), `uptime` for reboot cause.
3. If OSD node: `ceph -s` — expect `PGs may be unavailable`; **do NOT** reboot other OSD node simultaneously (2 replicas → data loss risk).
4. Recover: reboot node, wait Ready, verify `ceph -s` → HEALTH_OK, pods reschedule.
5. Document in CRON-DEPLOYMENT-LOG.md.

### 5.2 Ceph degraded / full (SEV-2)
1. `ceph -s`, `ceph health detail`, `ceph df` — check OSD down / near-full (`mon_osd_full_ratio`).
2. NEVER let cluster reach full — new writes block (k8s PVC hang).
3. Free space: remove unneeded snapshots/assets, increase ratio temporarily only as last resort.
4. If data integrity: stop writes to affected app (`kubectl scale deploy ... 0`), engage Backup-Administrator for restore path.

### 5.3 API server unavailable (SEV-2/1)
1. `systemctl status k3s` on node-1; `journalctl -u k3s -n 300`.
2. Single-master: if k3s won't start → **do not restart etcd blindly**; check DB dir on `/var/lib/rancher/k3s/server/db/`.
3. Verify secrets encryption config (`encryption-config.json`) matches state (`encryption-state.json`) before any etcd restore.
4. Restore path last resort: K8up snapshot of `/var/lib/rancher/k3s` + rollback routine.

### 5.4 Suspected intrusion / compromise (SEV-1)
1. **Preserve evidence first** — copy audit.log + journal logs to offline media before changes.
2. Isolate: revoke SSH keys, block node egress via UFW/iptables (SCS-FIREWALL chain) if lateral movement suspected.
3. Rotate credentials: k3s token, SA tokens, ArgoCD repo creds, SSH keys, registry creds.
4. Check: `kubectl get secrets` exposure, RBAC `kubectl auth can-i`, audit log for unknown actors, `journalctl -u ssh` for auth failures.
5. Escalate: IT operations; if personal data involved → **SEV-0** (Art. 33 below).

### 5.5 Data breach / personal data incident (SEV-0)
Mandatory (DSGVO):
- **Contain:** isolate workload, rotate creds, snapshot state for evidence.
- **Assess:** what data, whose, how many, duration, exposure (Art. 33(1)).
- **Notify supervisory authority within 72 h** via [DSB path] dpo@example.edu (or HDSIG requirements). IT operations coordinates.
- **Inform data subjects** when high risk (Art. 34).
- **Document** everything (incident register entry — below).

---

## 6. Notification & Documentation

- Internal: incident register entry in this section / CRON-DEPLOYMENT-LOG.md, or dedicated `INCIDENT-LOG-YYYYMMDD.md` under `docs/incidents/`.
- External (SEV-0 only): DSB/IT operations, 72 h deadline, keep proof of dispatch.
- Post-incident: **RCA within 14 days** — timeline, root cause, actions, measure back-refs (TOMs), lessons learned.

---

## 7. Escalation Matrix (time-boxed)

| Min after detection | Level | Action |
|---------------------|-------|--------|
| 0 | all | Acknowledge, log, assign IC |
| 30 min | SEV-1/2 | Containment begun; IT operations informed if infra |
| 60 min | SEV-1 | Status to IT operations; recovery plan |
| 4 h | SEV-0/1 | 72h-clock started for data breach; DSB notified |
| 24 h | SEV-2+ | Interim report in incident register |
| 14 days | all resolved | RCA + measure updates |

---

## 8. Ready / Preparedness checklist

- [x] K3s API audit logging active (2026-08-28)
- [x] Secrets encryption at rest (2026-08-28)
- [x] SSH + kernel hardening on all nodes
- [x] Backup routine (K8up/restic) + rollback scripts
- [ ] **Alerting** (Alertmanager → e-mail/Slack) — OPEN
- [ ] **Icinga2 service definitions** active — OPEN
- [ ] **DSB formally appointed** (DSFA M-09) — OPEN
- [ ] Regular IR tabletop drill (annual) — TODO
