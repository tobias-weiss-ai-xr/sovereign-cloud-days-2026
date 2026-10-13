# Sovereign Cloud Days 2026 — Workshop

**Session:** Agentic AI meets Sovereign Cloud: openEduSuite on SCS-verified legacy bare-metal hardware  
**Slot:** Sun, 25.10.2026, 11:15 · Workshop Stage · 60 min incl. Q&A  
**Format:** Workshop (interactive) · Draft v1.1

> Timeline: **~50 min Content + 10 min Q&A.** Flow: Motivation → Hands-on pi.dev → Cluster details → openEduSuite workload → Q&A. Interactive moments are marked with **[WS]**. Backup slides (architecture, agent trace, screencast) are available as a fallback.  
> Sources: `architecture/NETWORK-CONFIG.md`, `references/scs-kaas-compliance-report.md`, `references/COMPLIANCE-STATUS-REPORT.md`, `operations/DEVSECOPS-HARDENING-ASSESSMENT.md`, `paper-work/umr/01-betriebsmittel-scs.md` (each as of 2026-08). Values that cannot be substantiated are marked with `[verify]`.  
> Slide deck: `SCD-2026-openEduSuite-slides.html` (16 slides, self-contained, inline SVG diagrams, screenshots under `img/`).

---

## Motivation 1 · Intro — Why this talk? (3 min)

- Throw away legacy hardware? Most data centers have "retired" servers — often fully functional.
- Thesis: **A sovereign, AI-capable setup also works on "written-off" iron.**
- Today: a 3-node bare-metal SCS-verified K3s cluster, reused Huawei servers (rack clrz14, 3 of 8 servers), real agentic-AI workloads.
- openEduSuite is **not a toy**: HFD Ideenwettbewerb Digitale Souveränität, prize winner 2026-10-06, Philipps-Universität Marburg.
- "Not macht erfinderisch" (necessity breeds invention) — constraints are no excuse but the origin of good architecture.

**[WS]** Who among you runs "old hardware" in production themselves? → quick show of hands.

---

## Motivation 2 · Problem statement (3 min)

- Modern AI/cloud workloads → GPU racks, new HW, expensive. Sovereignty → vendor lock-in, dependencies.
- openEduSuite: a sovereign, AI-powered education platform — multi-tenant (edu, staff, students, sme, llm, predictive-agent).
- Requirements: auth (Keycloak/OIDC), email (Postfix + Stalwart + DKIMpy + OpenLDAP), collaboration, file storage, LLM-based agents.
- Challenge: all of this on **old Huawei hardware**, without new investment, SCS-compliant and GDPR-documented.

---

## Hands-on · pi.dev install + prompt testing (12 min)

- **Install (2 min):** `curl -fsSL https://pi.dev/install.sh | sh` (alternatively `npm i -g @earendil-works/pi-coding-agent`, Node 22.19+). Verify: `pi --version`.
- **Choose model (3 min):** `/login` → provider **opencode**; `/model` → **big pickle** (free, large — "the free big pickle"). Alternatives: `GROQ_API_KEY` / `GOOGLE_API_KEY` for further free-tier models.
- **Prompt testing (7 min):** starter prompts to try out:
  - "Explain SCS-0217 pod security in 3 sentences."
  - "Write a default-deny NetworkPolicy for namespace `llm`."
  - "PVC on ceph-rbd, 3-way replication — show the manifest."
  - "Ceph is HEALTH_WARN — give 3 first debugging steps."
  - "Sketch: student question → retrieval → Ollama CPU → answer."
- `/thinking` for reasoning level, `Ctrl+P` to switch models. The session is stored locally.

**[WS]** Who installed pi in 5 min? → walk around, help, collect questions for Q&A.

---

## Cluster 1 · The hardware (3 min)

- **3 × Huawei RH2288E V2** (rack clrz14 holds 8; in use: `clrz14-06` master, `clrz14-07`/`clrz14-08` worker).
  - **Form factor / BMC:** 2U rackmount, Huawei iMana 200 iBMC (dedicated service controller); BMC video Matrox G200eR2 → Ubuntu needs `nomodeset`.
  - **CPU:** 2× LGA 2011, Intel Xeon E5-2600 v2 (Ivy Bridge-EP), 6–12 cores/CPU, 80–130 W TDP. Exact model/clock `[verify]` (only readable via iBMC/BIOS).
  - **RAM:** 24× DDR3 ECC RDIMM (1066/1333/1600 MHz), max. 768 GB, populated ≥ 32 GB. Exact size `[verify]` (iBMC/BIOS).
  - **Storage:** 6× 512 GB SSD per server (LSI SAS, IT mode for Ceph) ≈ 3 TB raw. Ceph in the K3s cluster: **8 OSDs** (4 on `clrz14-06`, 2 each on `clrz14-07/08`), replication 3, `HEALTH_OK`.
  - **Network:** 2× Intel X540-AT2 10 GbE — `ens3f0` (mgmt RZ24, untagged) and `ens6f0`/VLAN 424 (internal). Firewall chain `SCS-FIREWALL` on `ens3f0`.
  - **GPU:** none. No GPU, no accelerator — AI inference runs on CPU.
- Why that is still enough: proper placement, quantization, deterministic scheduling, distributed Ceph storage.

**[WS]** How old is your oldest production system? — quick round.

---

## Motivation 3 · The detour: OpenStack/OVN collapse & the pivot (4 min)

- First architecture: OpenStack via OSISM/Kolla on VMs (OVN 25.03.1, Neutron).
- The bug that held everything up: **OVN 25.03.1 gateway redirect bug** → floating IPs dead on non-gateway chassis, ARP responders missing, DHCP broke down.
- Workarounds (ARP flows, LSP addresses) — fragile, "a reboot destroys the fix". The old test VM FIPs (`.181/.182/.184/.196`) and SNAT workarounds from this phase no longer apply today.
- Lesson: **complexity kills.** The VM/SDN architecture was the wrong abstraction for 3 bare-metal nodes.

---

## Cluster 2 · The pivot: SCS-verified bare-metal K3s (5 min)

- Decision: VMs out, **bare metal in** — 3 nodes, 1 cluster, node IPs `172.17.0.6/.7/.8` (internal VLAN 424).
- Stack (everything actually in operation):
  - **K3s v1.36.3+k3s1** — single server (master `clrz14-06`), embedded datastore (no separate etcd cluster). *Note: the docs sometimes say embedded etcd, sometimes SQLite — live datastore type `[verify]`.*
  - **Flannel VXLAN** (pod network `10.42.0.0/16`), **MetalLB L2** (FIPs), **HAProxy Ingress**.
  - **Ceph 18.2.8 (Reef)** — 8 OSDs, 3 MONs, replication 3, `cephx`; RBD + CephFS, `ceph-rbd` is the default storage class.
  - **ArgoCD v2.12.6** (GitOps), **K8up/Restic** (backup → SeaweedFS S3), local registry (`registry:2`, port 5001) as image mirror.
  - OS base: Ubuntu 24.04 LTS (kernel 6.8.0-137), containerd 2.3.3, runc 1.4.3.
- Network: mgmt **RZ24** `172.25.24.36-.38` (`ens3f0` untagged); internal **VLAN 424** `172.17.0.0/18`; **FIP pool RZ03** `172.25.3.181–.196` (MetalLB). In use: `.181` haproxy-ingress, `.182` argocd, `.183` stalwart, `.184` dkimpy, `.185` postfix, `.186` openldap; `.187–.196` free.
- Result: fewer layers, fewer sources of error, easier to operate.

---

## Cluster 3 · "SCS-verified" — what does that mean concretely? (5 min)

- **SCS KaaS compliance: 6/6 standards PASS** (verified 2026-08-23):
  - SCS-0201 CNCF conformance (444/444, 0 failed), SCS-0210 version (`v1.36.3`, within the recency window), SCS-0211 storage (`ceph-rbd` failure-safe default), SCS-0214 node distribution (3 nodes, topology labels `rz03-a/b/c`), SCS-0217 pod security, SCS-0219 networking (`kaas-networking-check` PASS; **37 NetworkPolicies** at test time, 40 live by now).
- **SCS-0217 fine-tuning:** 14/17 PASS, 3 WARN (K3s architecture limits: embedded etcd, no separate etcd CA/ACL).
- **DevSecOps hardening: 78/100 (C+)**, 4-phase plan (as of 2026-08-28):
  - Auth & authz 85, network security 80, pod security 75, monitoring & detection 70.
  - Audit & logging was 30/100 → **closed 2026-08-28**: K3s API audit logging active (`audit.log`, `apiserver_audit_event_total`).
  - Data protection 40/100 → secrets encryption at rest **enabled 2026-08-28** (AES-CBC); Ceph at-rest encryption still open.
  - Incident response was 20/100 → **closed 2026-08-28** (IR plan with SEV levels, GDPR Art. 33/34).
  - DevSecOps pipeline 25/100 → Trivy present but **not yet integrated into CI/CD**.
- **Known open gaps (honestly):** a second auth method (OIDC/webhook) is missing; pod security baseline `enforce` on **17 of 22 namespaces**, 5 deferred (`hostNetwork`/`hostPath`); central log aggregation (Loki) not deployed; Ceph at-rest encryption and MFA (planned 2027) open.
- **GDPR:** infrastructure DPIA/TOM/ROPA documented (`docs/paper-work/`), but the cluster is **not yet approved for personal data** (5 high residual risks, HRZ/DPO sign-off pending). Compliance is a process, not a checkbox.
- Compliance as a **product feature**: "verified" ≠ bullshit bingo but measurable tests.

**[WS]** Do you know the SCS test suite? — any guests using SCS? Show of hands.

---

## Workload 1 · openEduSuite — the workload (5 min)

- Sovereign education platform, operated in several tenants: `opendesk-edu`, `opendesk-staff`, `opendesk-students`, `opendesk-sme` + `llm` and `opendesk-predictive-agent`.
- Services (excerpt, all actually deployed/planned):
  - **Auth/OIDC:** Keycloak (issuer `id.*`), LDAP/OpenLDAP (`.186`, 389/636).
  - **Email stack:** Postfix (`.185`), Stalwart (`.183`, 25/587/465/143/993/8080), DKIMpy (`.184`).
  - **Collaboration/files:** Nextcloud, XWiki, Matrix, SOGo6, OpenProject.
- Image strategy: own **Nix builds on GHCR**, served via local Zot registry (ZenDiS/`opencode.de` now only an optional mirror).
- Agentic layer: LLM agents for learning support, automated summaries, tutoring — **meant seriously**: autonomous workflows, not just chat.
- Operation on limited HW: **quantization** of the models, CPU inference (Ollama, ns `llm`), batch instead of real-time streaming, deterministic scheduling (availability-zones lesson from the OVN days).
- Side note on operational reality: `opendesk-sme` is still `Degraded` (pre-render defects: stale image digests, missing `ums-stack-data-ums-ucr` ConfigMap) — transparent instead of glossed over.

---

## Workload 2 · The agentic workflow — concretely (5 min)

- Demo scenario: **automated learning short answer / summary.**
  1. Student question (in chat/frontend) → open-webui in namespace `llm`.
  2. Context enrichment: course material/documents + metrics from **Prometheus** (pod/node state) as a tool call.
  3. Inference: **Ollama** (image `ollama:0.32.13-nix`) on **CPU**, quantized model. Model name/size `[verify]` (not fixed in the sources).
  4. Answer + source citation back to the user.
- Why "agentic": the flow is **tool-using and multi-step** (retrieval → inference → verification), not a single prompt.
- Second agent in operation: **`predictive-agent`** (`v8.11-nix`) — risk scoring for pods/nodes with a Kalman filter + Markov chain; basis for proactive alerting (62 tracked pods, 15 marked "at-risk").
- Infrastructure link: the agent carries the state of the SCS instance with it — exactly the bridge "Agentic AI meets Sovereign Cloud".

---

## Cluster 4 · Operational experience & pitfalls (4 min)

- Problems actually encountered: registry/containerd HTTP, PodSecurity labels, NetworkPolicies (default-deny!), OIDC/auth migrations, stale image digests after upstream re-publish, missing Helm hook ConfigMaps.
- Monitoring: Prometheus + Grafana (7 dashboards) + `predictive-agent`, node-exporter, kube-state-metrics, Alertmanager; NRPE + 10 K3s checks per node (Icinga2 integration still open).
- Updates: SCS-compliant update routine with pre/post checks, Ceph-first, rolling node updates, rollback script (`scs-rollback.sh`).
- Backup/DR: K8up/Restic → SeaweedFS S3 (in-cluster), off-cluster mirror to `clrz12-02` (⚠️ currently a TLS certificate blocker).
- Firewall: `SCS-FIREWALL` on `ens3f0` allows 80/443/22/5001/31080/31443/123/ICMP, blocks 6443/10250/8472.

**[WS]** What was your worst operational incident last year? — 2–3 short stories.

---

## Workload 3 · Live demo (live, ~4 min)

- Cluster dashboard: 3 nodes, Ceph `HEALTH_OK` (8/8 OSDs), SCS compliance board (`scs_overall_update_readiness`).
- openEduSuite: login (Keycloak/OIDC) → an agentic workflow (automatic summary/learning short answer, see §8).
- Agent trace: how the agent uses the infra (graphic, brief) — Prometheus tool calls + Ollama inference.
- **Fallback plan if the demo fails:** screencast video + architecture diagram as a backup slide (backup slides marked in the deck). Screenshots for the fallback slide: update `[verify]` on site.

---

## Lessons learned & conclusion (3 min)

1. **Start small, fail fast:** OpenStack was the wrong complexity — the pivot was right.
2. **Bare metal instead of a VM layer** on 3 nodes: less abstraction, less debugging.
3. **Constraints are features:** quantization + scheduling beat hardware purchases.
4. **"Verified" sells:** SCS tests + DPIA open doors (government, education, university) — but only with honest gap reporting.
5. **Document like crazy:** runbooks, DPIA, checklists — otherwise your knowledge becomes a one-way street.

---

## 12 · Conclusion & outlook (2 min)

- What you take away today: legacy HW + SCS-verified + agentic AI = doable, now, for little money.
- Outlook: no GPU expansion planned — **edge inference and better quantization**, personalization per learning group, multi-site openEduSuite.
- Next steps in the cluster: roll out pod security to the remaining 5 namespaces, OIDC as a second auth method, Loki log aggregation, Trivy in CI, resolve off-cluster backup TLS, GDPR approval.

---

## Q&A (10 min)

- Questions are explicitly welcome — "what if" / architecture / rebuilding / licensing issues SCS/openEduSuite.
- Hands-on: go deeper on the pi.dev installation and prompts from the workshop part.
- Contact: tobias-weiss.org · graphwiz.ai · ki-kompetenz-training.org.

---

## Backlog / open items (v1.0)

Resolved items from v0.1:

- [x] **Real HW details added** (RH2288E V2: Xeon E5-2600 v2, DDR3 ECC RDIMM, 6× 512 GB SSD, 2× Intel X540-AT2 10 GbE, no GPU; exact CPU/RAM configuration marked `[verify]`, since only readable via iBMC/BIOS).
- [x] **Current SCS compliance status** (6/6 KaaS PASS, 444/444 CNCF; DevSecOps 78/100 with 17/22 pod security namespaces; P1 audit logging + secrets encryption + IR plan closed on 2026-08-28; open gaps named).
- [x] **Agent workflow made concrete** (learning short answer scenario: open-webui → Prometheus context → Ollama CPU inference → answer; plus `predictive-agent`).

Still open (to clarify on site):

- [ ] Update screenshots for the live demo fallback (iBMC KVM, ArgoCD, Grafana available; verify openEduSuite tenant screens).
- [ ] Verify openEduSuite detail screens (feature status of the tenants).
- [ ] **Finalize title wording with the organizers** — Carolin published the *old* title ("…openDesk Edu…with OpenStack SCS"); correction to "openEduSuite on SCS-verified legacy bare-metal hardware" still pending.
- [ ] Fine-tune the time budget after the rehearsal talk (new flow: motivation 6 + hands-on 12 + cluster 12 + workload 8 + lessons 3 + Q&A 10 = 51 + 9 buffer).

---

*Draft v1.1 created in 2026 with the assistance of an AI coding agent (pi). Technical facts from the sources documented in the repo (as of 2026-08); `[verify]` markers denote values that can only be confirmed on the cluster/iBMC. Slide deck: 16 slides (HTML, self-contained, inline SVG, screenshots). Workshop part: pi.dev install + prompt testing with `big pickle` (opencode free tier).*
