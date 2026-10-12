# Sovereign Cloud Days 2026 — Workshop

**Session:** Agentic AI meets Sovereign Cloud: openEduSuite on SCS-verified legacy bare-metal hardware  
**Slot:** So, 25.10.2026, 11:15 · Workshop Stage · 60 min inkl. Q&A  
**Format:** Workshop (interaktiv) · Draft v1.1

> Timeline: **~50 min Content + 10 min Q&A.** Flow: Motivation → Hands-on pi.dev → Cluster-Details → openEduSuite-Workload → Q&A. Interaktive Momente sind mit **[WS]** markiert. Ersatzfolien (Architektur, Agent-Trace, Screencast) liegen als Fallback bereit.  
> Quellen: `architecture/NETWORK-CONFIG.md`, `references/scs-kaas-compliance-report.md`, `references/COMPLIANCE-STATUS-REPORT.md`, `operations/DEVSECOPS-HARDENING-ASSESSMENT.md`, `paper-work/umr/01-betriebsmittel-scs.md` (Stand jeweils 2026-08). Nicht belegbare Werte sind mit `[verify]` markiert.  
> Slide-Deck: `SCD-2026-openEduSuite-slides.html` (16 Folien, self-contained, Inline-SVG-Diagramme, Screenshots unter `img/`).

---

## Motivation 1 · Intro — Warum dieser Talk? (3 min)

- Legacy-Hardware wegwerfen? Die meisten Rechenzentren haben "aussortierte" Server — oft voll funktionsfähig.
- These: **Souveränes, KI-fähiges Setup geht auch auf "abgeschriebenem" Eisen.**
- Heute: 3-node bare-metal SCS-verified K3s-Cluster, wiederverwendete Huawei-Server (Rack clrz14, 3 von 8 Servern), echte agentic-AI-Workloads.
- openEduSuite ist **kein Spielzeug**: HFD Ideenwettbewerb Digitale Souveränität, Preisträger 2026-10-06, Philipps-Universität Marburg.
- "Not macht erfinderisch" — Constraints sind keine Ausrede, sondern der Ursprung guter Architektur.

**[WS]** Wer von euch betreibt selbst "Alt-Hardware" produktiv? → kurz Handzeichen.

---

## Motivation 2 · Problemstellung (3 min)

- Moderne KI/Cloud-Workloads → GPU-Racks, neue HW, teuer. Souveränität → Vendor-Lockout, Abhängigkeiten.
- openEduSuite: souveräne, KI-gestützte Bildungsplattform — Multi-Tenant (edu, staff, students, sme, llm, predictive-agent).
- Anforderungen: Auth (Keycloak/OIDC), E-Mail (Postfix + Stalwart + DKIMpy + OpenLDAP), Kollaboration, Dateiablage, LLM-basierte Agenten.
- Herausforderung: Das alles auf **alter Huawei-Hardware**, ohne neue Investition, SCS-konform und DSGVO-dokumentiert.

---

## Hands-on · pi.dev install + Prompt-Testing (12 min)

- **Install (2 min):** `curl -fsSL https://pi.dev/install.sh | sh` (alternativ `npm i -g @earendil-works/pi-coding-agent`, Node 22.19+). Prüfen: `pi --version`.
- **Modell wählen (3 min):** `/login` → Provider **opencode**; `/model` → **big pickle** (kostenlos, groß — „the free big pickle"). Alternativen: `GROQ_API_KEY` / `GOOGLE_API_KEY` für weitere Free-Tier-Modelle.
- **Prompt-Testing (7 min):** Starter-Prompts zum Ausprobieren:
  - „Erkläre SCS-0217 Pod-Security in 3 Sätzen."
  - „Schreibe eine default-deny NetworkPolicy für Namespace `llm`."
  - „PVC auf ceph-rbd, 3-fach Replikation — zeige das Manifest."
  - „Ceph ist HEALTH_WARN — gib 3 erste Debug-Schritte."
  - „Skizziere: Studierendenfrage → Retrieval → Ollama-CPU → Antwort."
- `/thinking` für Reasoning-Level, `Ctrl+P` zum Modell-Wechseln. Session wird lokal gespeichert.

**[WS]** Wer hat pi in 5 Min installiert? → herumgehen, helfen, Fragen für Q&A sammeln.

---

## Cluster 1 · Die Hardware (3 min)

- **3 × Huawei RH2288E V2** (im Rack clrz14 stehen 8; genutzt: `clrz14-06` Master, `clrz14-07`/`clrz14-08` Worker).
  - **Formfaktor / BMC:** 2U Rackmount, Huawei iMana 200 iBMC (dedizierter Service-Controller); BMC-Video Matrox G200eR2 → Ubuntu braucht `nomodeset`.
  - **CPU:** 2× LGA 2011, Intel Xeon E5-2600 v2 (Ivy Bridge-EP), 6–12 Kerne/CPU, 80–130 W TDP. Genaues Modell/Takt `[verify]` (nur via iBMC/BIOS auslesbar).
  - **RAM:** 24× DDR3 ECC RDIMM (1066/1333/1600 MHz), max. 768 GB, bestückt ≥ 32 GB. Exakte Größe `[verify]` (iBMC/BIOS).
  - **Storage:** 6× 512 GB SSD pro Server (LSI SAS, IT-Mode für Ceph) ≈ 3 TB raw. Ceph im K3s-Cluster: **8 OSDs** (4 auf `clrz14-06`, je 2 auf `clrz14-07/08`), Replikation 3, `HEALTH_OK`.
  - **Netzwerk:** 2× Intel X540-AT2 10 GbE — `ens3f0` (Mgmt RZ24, untagged) und `ens6f0`/VLAN 424 (intern). Firewall-Chain `SCS-FIREWALL` auf `ens3f0`.
  - **GPU:** keine. Keine GPU, kein Beschleuniger — KI-Inferenz läuft auf CPU.
- Warum das dennoch reicht: richtige Platzierung, Quantisierung, deterministisches Scheduling, verteilter Ceph-Storage.

**[WS]** Wie alt ist euer ältestes produktives System? — kurze Runde.

---

## Motivation 3 · Der Umweg: OpenStack/OVN-Kollaps & der Pivot (4 min)

- Erste Architektur: OpenStack via OSISM/Kolla auf VMs (OVN 25.03.1, Neutron).
- Der Bug, der alles aufhielt: **OVN 25.03.1 Gateway-Redirect-Bug** → Floating IPs auf Nicht-Gateway-Chassis tot, ARP-Responder fehlten, DHCP brach weg.
- Arbeitearounds (ARP-Flows, LSP-Addresses) — fragil, "Reboot zerstört den Fix". Die alten Test-VM-FIPs (`.181/.182/.184/.196`) und SNAT-Workarounds aus dieser Phase gelten heute nicht mehr.
- Lehre: **Komplexität tötet.** Die VM-/SDN-Architektur war die falsche Abstraktion für 3 Bare-Metal-Nodes.

---

## Cluster 2 · Der Pivot: SCS-verified bare-metal K3s (5 min)

- Entscheidung: VMs raus, **bare metal rein** — 3 Nodes, 1 Cluster, Knoten-IPs `172.17.0.6/.7/.8` (internes VLAN 424).
- Stack (alles real im Betrieb):
  - **K3s v1.36.3+k3s1** — Single-Server (Master `clrz14-06`), eingebetteter Datastore (kein separater etcd-Cluster). *Hinweis: Doku nennt teils embedded etcd, teils SQLite — Live-Datastore-Typ `[verify]`.*
  - **Flannel VXLAN** (Pod-Netz `10.42.0.0/16`), **MetalLB L2** (FIPs), **HAProxy Ingress**.
  - **Ceph 18.2.8 (Reef)** — 8 OSDs, 3 MONs, Replikation 3, `cephx`; RBD + CephFS, `ceph-rbd` ist Default-StorageClass.
  - **ArgoCD v2.12.6** (GitOps), **K8up/Restic** (Backup → SeaweedFS S3), lokale Registry (`registry:2`, Port 5001) als Image-Mirror.
  - OS-Basis: Ubuntu 24.04 LTS (Kernel 6.8.0-137), containerd 2.3.3, runc 1.4.3.
- Netzwerk: Mgmt **RZ24** `172.25.24.36-.38` (`ens3f0` untagged); intern **VLAN 424** `172.17.0.0/18`; **FIP-Pool RZ03** `172.25.3.181–.196` (MetalLB). Belegt: `.181` haproxy-ingress, `.182` argocd, `.183` stalwart, `.184` dkimpy, `.185` postfix, `.186` openldap; `.187–.196` frei.
- Ergebnis: weniger Layer, weniger Fehlerquellen, einfacher betreibbar.

---

## Cluster 3 · "SCS-verified" — was heißt das konkret? (5 min)

- **SCS KaaS-Konformität: 6/6 Standards PASS** (verifiziert 2026-08-23):
  - SCS-0201 CNCF Conformance (444/444, 0 Failed), SCS-0210 Version (`v1.36.3`, im Recency-Window), SCS-0211 Storage (`ceph-rbd` failure-safe default), SCS-0214 Node-Distribution (3 Nodes, Topologie-Labels `rz03-a/b/c`), SCS-0217 Pod-Security, SCS-0219 Networking (`kaas-networking-check` PASS; **37 NetworkPolicies** zum Testzeitpunkt, live inzwischen 40).
- **SCS-0217 Feinschliff:** 14/17 PASS, 3 WARN (K3s-Architektur-Limits: embedded etcd, kein separates etcd-CA/ACL).
- **DevSecOps-Härtung: 78/100 (C+)**, 4-Phasen-Plan (Stand 2026-08-28):
  - Auth&Authz 85, Network-Security 80, Pod-Security 75, Monitoring&Detection 70.
  - Audit&Logging war 30/100 → **2026-08-28 geschlossen**: K3s-API-Audit-Logging aktiv (`audit.log`, `apiserver_audit_event_total`).
  - Data Protection 40/100 → Secrets-Encryption-at-rest **2026-08-28 aktiviert** (AES-CBC); Ceph-at-rest-Encryption weiterhin offen.
  - Incident Response war 20/100 → **2026-08-28 geschlossen** (IR-Plan mit SEV-Levels, DSGVO Art. 33/34).
  - DevSecOps-Pipeline 25/100 → Trivy vorhanden, aber **noch nicht in CI/CD integriert**.
- **Bekannte offene Lücken (ehrlich):** zweite Auth-Methode (OIDC/Webhook) fehlt; Pod-Security-Baseline `enforce` auf **17 von 22 Namespaces**, 5 deferred (`hostNetwork`/`hostPath`); zentrale Log-Aggregation (Loki) nicht deployed; Ceph-at-rest-Encryption und MFA (geplant 2027) offen.
- **DSGVO:** Infrastruktur-DSFA/TOM/VVT dokumentiert (`docs/paper-work/`), aber Cluster ist **noch nicht für personenbezogene Daten freigegeben** (5 hohe Restrisiken, HRZ-/DSB-Abnahme ausstehend). Compliance ist ein Prozess, kein Häkchen.
- Compliance als **Produktmerkmal**: "verified" ≠ Bullshit-Bingo, sondern messbare Tests.

**[WS]** Kennst du die SCS-Test-Suite? — Gäste, die SCS nutzen? Handzeichen.

---

## Workload 1 · openEduSuite — die Workload (5 min)

- Souveräne Bildungsplattform, betrieben in mehreren Tenants: `opendesk-edu`, `opendesk-staff`, `opendesk-students`, `opendesk-sme` + `llm` und `opendesk-predictive-agent`.
- Dienste (Auszug, alle real deployt/geplant):
  - **Auth/OIDC:** Keycloak (Issuer `id.*`), LDAP/OpenLDAP (`.186`, 389/636).
  - **E-Mail-Stack:** Postfix (`.185`), Stalwart (`.183`, 25/587/465/143/993/8080), DKIMpy (`.184`).
  - **Kollaboration/Dateien:** Nextcloud, XWiki, Matrix, SOGo6, OpenProject.
- Image-Strategie: eigene **Nix-Builds auf GHCR**, ausgeliefert über lokale Zot-Registry (ZenDiS/`opencode.de` nur noch optionaler Mirror).
- Agentic Layer: LLM-Agenten für Lernunterstützung, automatisierte Zusammenfassungen, Tutoring — **ernst gemeint**: autonome Arbeitsabläufe, nicht nur Chat.
- Betrieb auf begrenzter HW: **Quantisierung** der Modelle, CPU-Inferenz (Ollama, ns `llm`), Batch statt Echtzeit-Streaming, deterministisches Scheduling (Availability-Zones-Lektion aus OVN-Zeiten).
- Randnotiz Betriebsrealität: `opendesk-sme` ist noch `Degraded` (Pre-Render-Defekte: stale Image-Digests, fehlendes `ums-stack-data-ums-ucr`-ConfigMap) — transparent statt schöngeredet.

---

## Workload 2 · Der agentische Workflow — konkret (5 min)

- Szenario der Demo: **automatisierte Lern-Kurzantwort / Zusammenfassung.**
  1. Studierendenfrage (im Chat/Frontend) → open-webui im Namespace `llm`.
  2. Kontext-Anreicherung: Kursmaterial/Dokumente + Metriken aus **Prometheus** (Pod-/Node-Zustand) als Tool-Aufruf.
  3. Inferenz: **Ollama** (Image `ollama:0.32.13-nix`) auf **CPU**, quantisiertes Modell. Modellname/-größe `[verify]` (nicht in den Quellen fixiert).
  4. Antwort + Quellenangabe zurück an die Nutzerin.
- Warum "agentic": Der Ablauf ist **tool-nutzend und mehrschrittig** (Retrieval → Inferenz → Verifikation), nicht ein einzelner Prompt.
- Zweiter Agent im Betrieb: **`predictive-agent`** (`v8.11-nix`) — Risk-Scoring für Pods/Nodes mit Kalman-Filter + Markov-Chain; Grundlage für proaktives Alerting (62 getrackte Pods, 15 als "at-risk" markiert).
- Infrastruktur-Bezug: Der Agent trägt den Zustand der SCS-Instanz mit — genau die Brücke "Agentic AI meets Sovereign Cloud".

---

## Cluster 4 · Betriebserfahrung & Stolpersteine (4 min)

- Real erlebte Probleme: Registry-/containerd-HTTP, PodSecurity-Labels, NetworkPolicies (default-deny!), OIDC/auth-Umstellungen, stale Image-Digests nach Upstream-Re-Publish, fehlende Helm-Hook-ConfigMaps.
- Monitoring: Prometheus + Grafana (7 Dashboards) + `predictive-agent`, Node-Exporter, kube-state-metrics, Alertmanager; NRPE + 10 K3s-Checks pro Node (Icinga2-Integration noch offen).
- Updates: SCS-konforme Update-Routine mit Pre-/Post-Checks, Ceph-first, rollierende Node-Updates, Rollback-Skript (`scs-rollback.sh`).
- Backup/DR: K8up/Restic → SeaweedFS S3 (in-cluster), Off-Cluster-Mirror zu `clrz12-02` (⚠️ aktuell TLS-Zertifikat-Blocker).
- Firewall: `SCS-FIREWALL` auf `ens3f0` erlaubt 80/443/22/5001/31080/31443/123/ICMP, blockt 6443/10250/8472.

**[WS]** Was war euer schlimmster Betriebs-Vorfall im letzten Jahr? — 2–3 Kurzgeschichten.

---

## Workload 3 · Live-Demo (live, ~4 min)

- Cluster-Dashboard: 3 Nodes, Ceph `HEALTH_OK` (8/8 OSDs), SCS-Compliance-Board (`scs_overall_update_readiness`).
- openEduSuite: Login (Keycloak/OIDC) → ein agentischer Workflow (automatische Zusammenfassung/Lern-Kurzantwort, s. §8).
- Agent-Trace: wie der Agent die Infra nutzt (Grafik, kurz) — Prometheus-Toolcalls + Ollama-Inferenz.
- **Fallback-Plan bei Demo-Störung:** Screencast-Video + Architektur-Diagramm als Backup-Folie (Ersatzfolien im Deck markiert). Screenshots für die Fallback-Folie: `[verify]` vor Ort aktualisieren.

---

## Lessons Learned & Fazit (3 min)

1. **Fang klein an, scheitere schnell:** OpenStack war die falsche Komplexität — Pivot war richtig.
2. **Bare metal statt VM-Schicht** auf 3 Nodes: weniger Abstraktion, weniger Debugging.
3. **Constraints sind Features:** Quantisierung + Scheduling schlagen Hardware-Käufe.
4. **"Verified" verkauft:** SCS-Tests + DSFA öffnen Türen (Behörden, Bildung, Uni) — aber nur mit ehrlichem Lücken-Reporting.
5. **Dokumentiere wie ein Verrückter:** Runbooks, DSFA, Check-Listen — sonst wird dein Wissen zur Einbahnstraße.

---

## 12 · Fazit & Ausblick (2 min)

- Was du heute mitnimmst: Legacy-HW + SCS-verified + agentic AI = machbar, jetzt, für kleines Geld.
- Ausblick: kein GPU-Ausbau geplant — **Edge-Inferenz und bessere Quantisierung**, Personalisierung pro Lerngruppe, Multi-Site-openEduSuite.
- Nächste Schritte im Cluster: Pod-Security auf die verbleibenden 5 Namespaces ausrollen, OIDC als zweite Auth-Methode, Loki-Log-Aggregation, Trivy in CI, Off-Cluster-Backup-TLS lösen, DSGVO-Freigabe.

---

## Q&A (10 min)

- Fragen sind explizit erwünscht — „What if“ / Architektur / Nachbauen / Lizenzthemen SCS/openEduSuite.
- Hands-on: pi.dev-Installation und Prompts aus dem Workshop-Teil nachvertiefen.
- Kontakt: tobias-weiss.org · graphwiz.ai · ki-kompetenz-training.org.

---

## Backlog / offene Punkte (v1.0)

Aufgelöste Punkte aus v0.1:

- [x] **Echte HW-Details ergänzt** (RH2288E V2: Xeon E5-2600 v2, DDR3 ECC RDIMM, 6× 512 GB SSD, 2× Intel X540-AT2 10 GbE, keine GPU; genaue CPU-/RAM-Bestückung als `[verify]` markiert, da nur via iBMC/BIOS auslesbar).
- [x] **Aktueller SCS-Compliance-Stand** (6/6 KaaS PASS, 444/444 CNCF; DevSecOps 78/100 mit 17/22 Pod-Security-Namespaces; P1 Audit-Logging + Secrets-Encryption + IR-Plan am 2026-08-28 geschlossen; offene Lücken benannt).
- [x] **Agent-Workflow konkretisiert** (Szenario Lern-Kurzantwort: open-webui → Prometheus-Kontext → Ollama-CPU-Inferenz → Antwort; plus `predictive-agent`).

Weiterhin offen (vor Ort klären):

- [ ] Screenshots für Live-Demo-Fallback aktualisieren (iBMC-KVM, ArgoCD, Grafana vorhanden; openEduSuite-Tenant-Screens verifizieren).
- [ ] openEduSuite-Detail-Screens verifizieren (Feature-Stand der Tenants).
- [ ] **Titel-Formulierung final mit Orga abstimmen** — Carolin hat den *alten* Titel veröffentlicht („…openDesk Edu…with OpenStack SCS“); Korrektur zu „openEduSuite on SCS-verified legacy bare-metal hardware“ steht aus.
- [ ] Zeitbudget nach Probevortrag feinjustieren (neuer Flow: Motivation 6 + Hands-on 12 + Cluster 12 + Workload 8 + Lessons 3 + Q&A 10 = 51 + 9 Puffer).

---

*Draft v1.1 erstellt 2026 mit Unterstützung eines KI-Coding-Agenten (pi). Technische Fakten aus den im Repo dokumentierten Quellen (Stand 2026-08); `[verify]`-Marker kennzeichnen Werte, die nur am Cluster/iBMC bestätigt werden können. Slide-Deck: 16 Folien (HTML, self-contained, Inline-SVG, Screenshots). Workshop-Teil: pi.dev-Install + Prompt-Testing mit `big pickle` (opencode-Free-Tier).*
