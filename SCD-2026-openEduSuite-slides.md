---
marp: true
size: 16:9
paginate: true
html: true
theme: default
style: |
  :root{
    --bg:#e9edf1; --slide:#f7f9fb; --ink:#14202e; --muted:#5b6b7c;
    --accent:#0b6e99; --accent2:#1a7f6b; --warn:#b3560e; --line:#d3dae1;
  }
  section{
    background:var(--slide); color:var(--ink);
    font-family:"Segoe UI",system-ui,-apple-system,Roboto,Helvetica,Arial,sans-serif;
    font-size:22px; padding:48px 64px;
  }
  section::after{ color:#9aa6b3; font-size:14px; font-weight:700; }
  h1{ font-size:52px; line-height:1.1; margin:0 0 12px 0; font-weight:800; color:var(--ink); }
  h2{ font-size:34px; line-height:1.15; margin:0 0 20px 0; font-weight:750; color:var(--ink); }
  p{ margin:0 0 12px 0; line-height:1.32; }
  ul{ margin:0; padding-left:0; list-style:none; }
  li{ position:relative; padding-left:30px; margin:0 0 14px 0; font-size:23px; line-height:1.3; }
  li::before{ content:""; position:absolute; left:4px; top:.5em; width:10px; height:10px; border-radius:2px; background:var(--accent); }
  strong{ color:var(--ink); }
  em{ color:var(--warn); font-style:normal; font-weight:700; }
  .accent{ color:var(--accent2); font-weight:700; }
  .kicker{ font-size:15px; letter-spacing:.14em; text-transform:uppercase; color:var(--accent); font-weight:700; margin-bottom:8px; }
  .lead{ font-size:20px; color:var(--muted); }
  .small{ font-size:16px; color:var(--muted); line-height:1.4; }
  code{ background:#e8eef3; padding:1px 5px; border-radius:3px; font-size:.88em; color:#0b3a55; }
  pre{ background:#0f1c2a; border-radius:6px; }
  pre code{ background:transparent; color:#cde8ff; font-size:19px; }
  .card{ background:#fff; border:1px solid var(--line); border-left:5px solid var(--accent);
    border-radius:5px; padding:14px 18px; margin:0 0 12px 0; font-size:20px; line-height:1.32; }
  .card.green{ border-left-color:var(--accent2); }
  .card.warn{ border-left-color:var(--warn); }
  .grid2{ display:grid; grid-template-columns:1fr 1fr; gap:16px 30px; }
  .kv{ font-size:21px; line-height:1.3; }
  .kv b{ display:block; font-size:13px; letter-spacing:.08em; text-transform:uppercase; color:var(--accent); margin-bottom:2px; }
  table{ border-collapse:collapse; width:100%; font-size:18px; margin:8px 0; }
  th{ background:#0f1c2a; color:#fff; padding:7px 12px; text-align:left; font-size:14px; letter-spacing:.05em; text-transform:uppercase; }
  td{ padding:7px 12px; border-bottom:1px solid var(--line); vertical-align:top; }
  tr:nth-child(even) td{ background:#f0f4f7; }
  .seal{ font-weight:700; color:var(--warn); }
  .big{ font-size:34px; font-weight:800; }
  .ok{ color:var(--accent2); font-weight:700; }
  .ws{ background:#fff6e8; border:1px solid #f0d9b5; border-radius:5px; padding:10px 16px;
    font-size:18px; color:#7a4a08; font-weight:600; }
  .tag{ display:inline-block; font-size:14px; font-weight:700; letter-spacing:.08em; text-transform:uppercase;
    color:#fff; background:var(--accent2); padding:3px 9px; border-radius:3px; margin-right:8px; }
  figcaption{ font-size:15px; color:var(--muted); margin-top:5px; }
  img{ display:block; margin:0 auto; max-height:330px; border:1px solid var(--line); border-radius:5px; background:#fff; }
  .center{ text-align:center; }
  .svg-wrap{ text-align:center; }
  .svg-wrap svg{ max-width:100%; height:auto; }
  section.title{ justify-content:center; }
  section.title .brand{ font-size:17px; font-weight:700; color:var(--accent);
    letter-spacing:.16em; text-transform:uppercase; margin-bottom:14px; }
  section.title h1{ font-size:56px; }
  section.title .sub{ font-size:25px; color:var(--muted); margin-bottom:24px; line-height:1.3; }
  section.title .meta{ font-size:18px; }
  section.title .meta span{ color:var(--muted); }
---

<!-- _class: title -->

<div class="brand">Sovereign Cloud Days 2026 · Workshop Stage</div>

# Agentic AI meets Sovereign Cloud

<div class="sub">openEduSuite on SCS-verified legacy bare-metal hardware</div>

<div class="meta">Sun, 25.10.2026 · 11:15 · 60 min incl. Q&A<br>
<span>Tobias Weiß · HRZ Philipps-Universität Marburg</span></div>

<!--
Speaker note: Welcome. Thesis: a sovereign, AI-capable setup on written-off iron.
openEduSuite = HFD award winner 2026. Agenda: motivation → hands-on pi.dev → cluster → workload → Q&A.
~50 min content + 10 min Q&A. [WS] marker = audience interaction.
-->

---

<div class="kicker">Motivation · 3 min</div>

## Legacy hardware isn't junk

- Data centers have **decommissioned servers** — often fully functional.
- A sovereign, AI-capable setup runs on <span class="accent">written-off iron</span>.
- 3 × Huawei RH2288E V2 (~2013) → SCS-verified K3s cluster.

<div class="card green">openEduSuite: HFD Digital Sovereignty Ideas Competition — winner 2026-10-06.</div>

<div class="ws"><span class="tag">WS</span>Who runs “legacy hardware” in production themselves?</div>

<!--
Speaker note: Keep it short. Acknowledge the show of hands. No marketing — an honest field report.
The HFD prize as a signal of trust, not self-congratulation.
-->

---

<div class="kicker">Motivation · The pivot · 3 min</div>

## From OpenStack to bare-metal K3s

<div class="svg-wrap">
<svg viewBox="0 0 1100 200" width="100%">
  <rect x="20" y="40" width="380" height="120" rx="8" fill="#fdeaea" stroke="#c0392b" stroke-width="2"/>
  <text x="210" y="72" text-anchor="middle" font-size="20" font-weight="700" fill="#c0392b">OpenStack / OVN on VMs</text>
  <text x="210" y="98" text-anchor="middle" font-size="15" fill="#7a3b32">OVN 25.03.1 gateway bug</text>
  <text x="210" y="118" text-anchor="middle" font-size="15" fill="#7a3b32">FIPs dead, DHCP broke</text>
  <text x="210" y="142" text-anchor="middle" font-size="14" fill="#9a4a3a">“Reboot destroys the fix”</text>
  <path d="M 415 100 L 525 100" stroke="#5b6b7c" stroke-width="3" fill="none" marker-end="url(#arr)"/>
  <text x="470" y="88" text-anchor="middle" font-size="14" fill="#5b6b7c" font-weight="600">Pivot</text>
  <rect x="540" y="40" width="520" height="120" rx="8" fill="#e8f5ee" stroke="#1a7f6b" stroke-width="2"/>
  <text x="800" y="72" text-anchor="middle" font-size="20" font-weight="700" fill="#1a7f6b">Bare-metal K3s (SCS-verified)</text>
  <text x="800" y="98" text-anchor="middle" font-size="15" fill="#1a5447">3 nodes · Flannel · MetalLB · Ceph</text>
  <text x="800" y="118" text-anchor="middle" font-size="15" fill="#1a5447">6/6 KaaS standards PASS · 444/444 CNCF</text>
  <text x="800" y="142" text-anchor="middle" font-size="14" fill="#3a6b5e">fewer layers, fewer failure points</text>
  <defs><marker id="arr" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#5b6b7c"/></marker></defs>
</svg>
</div>

<div class="small center">The VM/SDN abstraction was too heavy for 3 nodes — bare metal is leaner.</div>

<!--
Speaker note: Keep the learning curve brief: the OVN gateway redirect bug showed that the abstraction
was too heavy for 3 nodes. Not “OpenStack is bad,” but “it didn't fit the scale.”
-->

---

<div class="kicker">Hands-on · pi.dev install · 2 min</div>

## Install pi

<div class="lead">One command is enough — the free tier needs no API key.</div>

```
curl -fsSL https://pi.dev/install.sh | sh
```

- Alternatively: `npm i -g @earendil-works/pi-coding-agent` (Node 22.19+)
- Verify: `pi --version`
- Start: `cd <projekt> && pi`

<!--
Speaker note: Start of the hands-on part. Say upfront: “You don't need a paid API key.”
The curl installer pins all dependencies. Allow 2 min, walk around, help.
-->

---

<div class="kicker">Hands-on · Choosing a model · 3 min</div>

## Start for free — big pickle

- `/login` → provider **opencode**
- `/model` → **big pickle** (large, free)
- Or free tier: `GROQ_API_KEY` / `GOOGLE_API_KEY`

<div class="card green">The “free big pickle” is enough for agentic experiments — no cost risk.</div>

<!--
Speaker note: big pickle on the opencode provider is free and large.
Alternatives: GROQ and Google also have a free tier. /thinking for reasoning level,
Ctrl+P to switch models. The session is stored locally.
-->

---

<div class="kicker">Hands-on · Prompt ideas · 6 min</div>

## Starter prompts to try

- “Explain SCS-0217 Pod-Security in 3 sentences.”
- “Write a default-deny NetworkPolicy for the `llm` namespace.”
- “PVC on ceph-rbd, 3× replication — show the manifest.”
- “Ceph is HEALTH_WARN — give 3 first debugging steps.”
- “Outline: student question → retrieval → Ollama CPU → answer.”

<div class="ws"><span class="tag">WS</span>Who installed pi in 5 min? → walk around, help.</div>

<!--
Speaker note: The heart of the workshop. 7 min for your own prompts. If rate-limited,
fall back to GROQ/Google. Share with a neighbor if you have no laptop. Collect questions for Q&A.
-->

---

<div class="kicker">Cluster · Hardware · 3 min</div>

## 3 × Huawei RH2288E V2 — no GPU

<div class="grid2">
  <div class="kv"><b>CPU</b>2× Xeon E5-2600 v2 (Ivy Bridge-EP) · 6–12 cores</div>
  <div class="kv"><b>RAM</b>24× DDR3 ECC RDIMM · max 768 GB</div>
  <div class="kv"><b>Storage</b>6× 512 GB SSD · Ceph 8 OSDs · Repl. 3</div>
  <div class="kv"><b>Network</b>2× Intel X540 10 GbE · no GPU</div>
</div>

<figure>
<img src="img/scs-imana-hw.png" alt="iBMC iMana hardware view">
<figcaption class="center">iBMC iMana — hardware view (clrz14-06/07/08)</figcaption>
</figure>

<div class="small center">CPU model / RAM size: readable only via iBMC/BIOS → [verify]</div>

<!--
Speaker note: Rack clrz14: 8 servers, 06 (master) + 07/08 (worker) in use. ~13 years old.
Honestly: CPU SKU and RAM size are [verify]. No GPU framing — AI inference runs on CPU.
-->

---

<div class="kicker">Cluster · Network · 3 min</div>

## Three networks, one firewall

<div class="svg-wrap">
<svg viewBox="0 0 1000 280" width="100%">
  <g font-size="14" font-weight="700" fill="#14202e">
    <rect x="130" y="20" width="120" height="40" rx="5" fill="#e8f0f7" stroke="#0b6e99" stroke-width="2"/>
    <text x="190" y="45" text-anchor="middle">clrz14-06</text>
    <rect x="290" y="20" width="120" height="40" rx="5" fill="#e8f0f7" stroke="#0b6e99" stroke-width="2"/>
    <text x="350" y="45" text-anchor="middle">clrz14-07</text>
    <rect x="450" y="20" width="120" height="40" rx="5" fill="#e8f0f7" stroke="#0b6e99" stroke-width="2"/>
    <text x="510" y="45" text-anchor="middle">clrz14-08</text>
  </g>
  <rect x="40" y="90" width="620" height="46" rx="5" fill="#f0f4f7" stroke="#5b6b7c" stroke-width="1"/>
  <text x="60" y="118" font-size="15" font-weight="700" fill="#5b6b7c">Mgmt RZ24</text>
  <text x="350" y="118" font-size="14" fill="#14202e" text-anchor="middle">172.25.24.36–.38 · ens3f0 untagged · SSH</text>
  <rect x="40" y="150" width="620" height="46" rx="5" fill="#e8f5ee" stroke="#1a7f6b" stroke-width="1"/>
  <text x="60" y="178" font-size="15" font-weight="700" fill="#1a7f6b">Internal</text>
  <text x="350" y="178" font-size="14" fill="#14202e" text-anchor="middle">VLAN 424 · 172.17.0.0/18 · .6/.7/.8 · Flannel VXLAN</text>
  <rect x="40" y="210" width="620" height="46" rx="5" fill="#fff6e8" stroke="#b3560e" stroke-width="1"/>
  <text x="60" y="238" font-size="15" font-weight="700" fill="#b3560e">FIP RZ03</text>
  <text x="350" y="238" font-size="14" fill="#14202e" text-anchor="middle">172.25.3.181–.196 · MetalLB L2 · .181 haproxy · .182 argocd · .183–.186 …</text>
  <rect x="700" y="90" width="260" height="166" rx="5" fill="#fdeaea" stroke="#c0392b" stroke-width="1.5"/>
  <text x="830" y="118" text-anchor="middle" font-size="15" font-weight="700" fill="#c0392b">SCS-FIREWALL</text>
  <text x="830" y="142" text-anchor="middle" font-size="13" fill="#7a3b32">allow: 80/443/22</text>
  <text x="830" y="160" text-anchor="middle" font-size="13" fill="#7a3b32">5001/31080/31443</text>
  <text x="830" y="178" text-anchor="middle" font-size="13" fill="#7a3b32">123/ICMP</text>
  <text x="830" y="200" text-anchor="middle" font-size="13" fill="#7a3b32">drop: 6443/10250</text>
  <text x="830" y="218" text-anchor="middle" font-size="13" fill="#7a3b32">8472</text>
</svg>
</div>

<div class="small center">ens3f0: mgmt + FIP (VLAN 3) · ens6f0: internal (VLAN 424) · iBMC out-of-band</div>

<!--
Speaker note: Three networks on 2× 10 GbE. Mgmt RZ24 (SSH), internal VLAN 424 (K3s pods),
FIP RZ03 (MetalLB L2, external services). Firewall on ens3f0. iBMC separate (out-of-band).
-->

---

<div class="kicker">Cluster · K3s stack · 4 min</div>

## The stack — bare-metal in production

<div class="svg-wrap">
<svg viewBox="0 0 700 360" width="100%">
  <g font-size="18" font-weight="700" text-anchor="middle">
    <rect x="40" y="10"  width="620" height="44" rx="6" fill="#0b6e99"/><text x="350" y="38" fill="#fff">openEduSuite Workloads (edu · staff · students · sme · llm)</text>
    <rect x="40" y="62"  width="620" height="44" rx="6" fill="#1a7f6b"/><text x="350" y="90" fill="#fff">ArgoCD (GitOps) · K8up/Restic (backup → SeaweedFS S3)</text>
    <rect x="40" y="114" width="620" height="44" rx="6" fill="#e8f0f7" stroke="#0b6e99"/><text x="350" y="142" fill="#14202e">Ceph 18.2.8 Reef — 8 OSDs, RBD + CephFS, Repl. 3</text>
    <rect x="40" y="166" width="620" height="44" rx="6" fill="#e8f0f7" stroke="#0b6e99"/><text x="350" y="194" fill="#14202e">Flannel VXLAN · MetalLB L2 · HAProxy Ingress</text>
    <rect x="40" y="218" width="620" height="44" rx="6" fill="#e8f0f7" stroke="#0b6e99"/><text x="350" y="246" fill="#14202e">K3s v1.36.3+k3s1 · Single-server · embedded datastore</text>
    <rect x="40" y="270" width="620" height="44" rx="6" fill="#f0f4f7" stroke="#5b6b7c"/><text x="350" y="298" fill="#5b6b7c">Ubuntu 24.04 LTS · containerd 2.3.3 · runc 1.4.3</text>
    <rect x="40" y="322" width="620" height="34" rx="6" fill="#1a1a1a"/><text x="350" y="344" fill="#fff" font-size="15">3 × Huawei RH2288E V2 (bare metal)</text>
  </g>
</svg>
</div>

<div class="small center">444/444 CNCF conformance · 6/6 SCS KaaS standards · DevSecOps 78/100</div>

<!--
Speaker note: Read from the bottom up: metal → OS → K3s → CNI/LB → Ceph → GitOps → workloads.
All real in production, not a lab. ArgoCD manages ~40 workloads. K3s datastore: embedded ([verify]).
-->

---

<div class="kicker">Cluster · SCS-verified · 2 min</div>

## 6/6 KaaS standards PASS — measurable

<figure>
<img src="img/scs-compliance-check.png" alt="SCS KaaS compliance report" style="max-height:320px">
<figcaption class="center">SCS KaaS compliance check (2026-08-23)</figcaption>
</figure>

- **SCS-0201** CNCF 444/444 · **0210** v1.36.3 · **0211** ceph-rbd
- **0214** 3 nodes · **0217** Pod-Security · **0219** Networking

<div class="card warn">Open: OIDC as 2nd auth · Pod-Security 17/22 NS · Loki/Trivy CI · Ceph at rest · GDPR clearance.</div>

<!--
Speaker note: “Verified” = measurable tests, no bullshit bingo. But name the open gaps clearly
— that's the selling point with public authorities and universities. GDPR: the cluster is NOT
yet cleared for personal data.
-->

---

<div class="kicker">Self-check · EU Cloud Sovereignty score · 2 min</div>

## 73.5 % Sovereignty Score — SEAL-1

Method: **EU Cloud Sovereignty Framework** (official calculator, Jun 2026) —
weighted **Sovereignty Score** + **SEAL** level (weakest link across all 48 criteria).

| Objective | W | Score | SEAL |
|---|---|---|---|
| SOV-1 Strategic | 20 % | <span class="ok">**94 %**</span> | SEAL-4 |
| SOV-4 Operational | 15 % | <span class="ok">**83 %**</span> | SEAL-3 |
| SOV-6 Technology | 15 % | <span class="ok">**80 %**</span> | SEAL-3 |
| SOV-3 Data & AI | 10 % | 75 % | SEAL-1 |
| SOV-2 Legal & Jurisdictional | 10 % | 71 % | SEAL-1 |
| SOV-7 Security & Compliance | 15 % | 64 % | SEAL-1 |
| SOV-5 Supply Chain | 10 % | 50 % | SEAL-1 |
| SOV-8 Environmental | 5 % | 19 % | SEAL-1 |

<div class="card warn">High score — low SEAL. SEAL is the <strong>weakest link</strong>: non-EU hardware
(Huawei/Intel, SOV-5), no formal EAL certification (SOV-7), no PUE/emissions reporting (SOV-8).</div>

<div class="card green">Levers to SEAL ≥ 3: EU-fabricated platform / hardware provenance · formal EAL cert · PUE &amp; CSRD reporting.</div>

<!--
Speaker note: This is a self-assessment against the EU framework, not an official certification.
Honest framing on purpose: the reused Huawei/Intel hardware caps the SEAL at 1 despite a 73.5%
score — strategy/ops/tech are strong, the supply chain and energy reporting are the drags.
Re-run: self-assessment/self-assessment-score.js (48 criteria, mapped in EU-sovereignty-assessment.md).
-->

---

<div class="kicker">Cluster · Operations · 2 min</div>

## What we learned in operation

<figure>
<img src="img/grafana-k3s.png" alt="Grafana K3s Dashboard" style="max-height:320px">
<figcaption class="center">Grafana K3s dashboard (7 dashboards, predictive-agent)</figcaption>
</figure>

- Stale digests, default-deny NetworkPolicies, OIDC migration — all resolved and documented
- Updates: Ceph-first, rolling, rollback script · backup: K8up → SeaweedFS S3

<!--
Speaker note: Frame it positively: every stumbling block was resolved and documented.
Firewall: SCS-FIREWALL on ens3f0. 2–3 lessons as a story, not a complaint.
-->

---

<div class="kicker">openEduSuite · Workload · 4 min</div>

## Sovereign education platform, multi-tenant

<div class="grid2">
  <div class="kv"><b>Tenants</b>edu · staff · students · sme · llm · predictive-agent</div>
  <div class="kv"><b>Auth</b>Keycloak / OIDC · OpenLDAP (.186)</div>
  <div class="kv"><b>Email</b>Postfix (.185) · Stalwart (.183) · DKIMpy (.184)</div>
  <div class="kv"><b>Collaboration</b>Nextcloud · XWiki · Matrix · SOGo6 · OpenProject</div>
</div>

<div class="small">Images: our own Nix builds on GHCR → local Zot registry. `opendesk-sme` still Degraded (stale digests).</div>

<!--
Speaker note: Multi-tenant platform for education. Auth via Keycloak/OIDC.
Email stack fully sovereign. Honestly call out opendesk-sme as Degraded.
-->

---

<div class="kicker">openEduSuite · Agentic Workflow · 4 min</div>

## Learning answer in 4 steps

<div class="svg-wrap">
<svg viewBox="0 0 1100 200" width="100%">
  <g font-size="15" font-weight="600" text-anchor="middle">
    <rect x="20" y="50" width="200" height="100" rx="8" fill="#e8f0f7" stroke="#0b6e99" stroke-width="2"/>
    <text x="120" y="80" fill="#0b6e99" font-weight="700">1 · Question</text>
    <text x="120" y="105" fill="#14202e" font-size="13">Student question</text>
    <text x="120" y="125" fill="#5b6b7c" font-size="13">open-webui (ns llm)</text>
    <path d="M 225 100 L 285 100" stroke="#5b6b7c" stroke-width="2.5" fill="none" marker-end="url(#arr2)"/>
    <rect x="290" y="50" width="200" height="100" rx="8" fill="#e8f5ee" stroke="#1a7f6b" stroke-width="2"/>
    <text x="390" y="80" fill="#1a7f6b" font-weight="700">2 · Retrieval</text>
    <text x="390" y="105" fill="#14202e" font-size="13">Course material</text>
    <text x="390" y="125" fill="#5b6b7c" font-size="13">+ Prometheus metrics</text>
    <path d="M 495 100 L 555 100" stroke="#5b6b7c" stroke-width="2.5" fill="none" marker-end="url(#arr2)"/>
    <rect x="560" y="50" width="200" height="100" rx="8" fill="#fff6e8" stroke="#b3560e" stroke-width="2"/>
    <text x="660" y="80" fill="#b3560e" font-weight="700">3 · Inference</text>
    <text x="660" y="105" fill="#14202e" font-size="13">Ollama on CPU</text>
    <text x="660" y="125" fill="#5b6b7c" font-size="13">quantized model</text>
    <path d="M 765 100 L 825 100" stroke="#5b6b7c" stroke-width="2.5" fill="none" marker-end="url(#arr2)"/>
    <rect x="830" y="50" width="250" height="100" rx="8" fill="#e8f0f7" stroke="#0b6e99" stroke-width="2"/>
    <text x="955" y="80" fill="#0b6e99" font-weight="700">4 · Answer + sources</text>
    <text x="955" y="105" fill="#14202e" font-size="13">with source citation</text>
    <text x="955" y="125" fill="#5b6b7c" font-size="13">to the user</text>
  </g>
  <defs><marker id="arr2" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#5b6b7c"/></marker></defs>
</svg>
</div>

<div class="card green" style="font-size:18px"><strong>predictive-agent v8.11-nix:</strong> Risk scoring (Kalman + Markov) for 62 pods — proactive alerting.</div>

<!--
Speaker note: “Agentic” = tool-using, multi-step (retrieval → inference → verification),
not a single prompt. The agent carries the cluster state with it — the bridge
“Agentic AI meets Sovereign Cloud.” Model name [verify].
-->

---

<div class="kicker">openEduSuite · Live demo · 4 min</div>

## Cluster, login, agent trace

<figure>
<img src="img/scs-ibmc-desktop-kvm.png" alt="iBMC KVM console (live)" style="max-height:320px">
<figcaption class="center">Live iBMC KVM console — server console via Pale Moon + Java Web Start</figcaption>
</figure>

- Dashboard: 3 nodes · Ceph HEALTH OK (8/8) · SCS board
- Login via Keycloak/OIDC → agentic workflow

<div class="card warn"><strong>Fallback:</strong> Screencast + architecture diagram in case the demo stalls.</div>

<!--
Speaker note: Test beforehand: tunnel/login, Ceph status, open-webui.
If it stalls: calmly switch to the fallback. Watch the time — 4 min. hard stop.
-->

---

<div class="kicker">Lessons · 3 min</div>

## Five takeaways

- **Start small, learn fast** — OpenStack didn't fit the scale.
- **Bare metal instead of a VM layer** — less abstraction, more control.
- **Constraints are features** — quantization beats buying GPUs.
- **“Verified” convinces** — SCS tests open doors, with honest gap reporting.
- **Document like a madman** — runbooks, DPIAs, checklists.

<!--
Speaker note: The essence. Stress point 4: Verified opens doors with public authorities and universities — but only with honest gaps.
Point 5: runbooks, DPIAs, checklists — otherwise knowledge is a one-way street.
-->

---

<div class="kicker">Q&A · 10 min</div>

## Questions & discussion

- Architecture, rebuilding it, SCS/openEduSuite licensing topics
- Hands-on: pi.dev installation and prompts from the workshop
- Contact: tobias-weiss.org · graphwiz.ai · ki-kompetenz-training.org

<div class="card green"><strong>Backup slides:</strong> architecture diagram · agent trace · screencast · cluster fact sheet.</div>

<!--
Speaker note: Q&A moderation: collect “what if” questions. For detailed questions on [verify] values,
honestly point to the source/iBMC. Have backup slides ready. Contact links for follow-up.
-->
