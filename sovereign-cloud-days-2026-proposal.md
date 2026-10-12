# Sovereign Cloud Days 2026 — Talk Proposal

Format: Talk — 25 minutes (+ 5 minutes Q&A)
Type: Practical report / Case study

---

## What is your talk about?

A practical case study on running agentic AI workloads (openEduSuite) on a sovereign, SCS-verified bare-metal cluster built from legacy Huawei servers — and how "Not macht erfinderisch" (necessity breeds invention) turned hardware and platform limitations into engineering wins.

Why this talk, why now:
- Agentic AI meets SCS — the convergence of sovereign cloud infrastructure with autonomous AI workloads is the defining challenge of 2026.
- Legacy hardware reality — most orgs can't buy new GPU racks; proving sovereign AI works on existing iron is the credible path to adoption.
- Real bugs, real fixes — an actual OVN 25.03.1 gateway redirect bug, diagnosed and worked around in production.

## Talk Title

Agentic AI meets Sovereign Cloud: openEduSuite on SCS-verified legacy bare-metal hardware

## Description

What if your cloud's constraints became its superpower?

In this practical case study, we show how openEduSuite — a sovereign, AI-powered educational platform — runs as an agentic workload on a 3-node SCS-verified bare-metal cluster (K3s) built from legacy Huawei servers, the kind of hardware most teams would recycle.

We walk the full stack: Huawei hardware repurposing, a bare-metal K3s platform (Flannel, MetalLB, HAProxy ingress), Ceph storage, and HA services (Keepalived, Galera). Along the way we share the real fights: an earlier OpenStack/OVN phase collapsed on a 25.03.1 gateway redirect bug that broke floating IPs — we ditched the VMs and moved the workloads to SCS-verified bare-metal, proving sovereign AI runs on recycled iron.

The theme: "Not macht erfinderisch" — necessity breeds invention. Constrained hardware + upstream bugs forced pragmatic engineering: OVS tuning for legacy NICs, LLM quantization for limited CPU, and deterministic scheduling instead of hoping for gateway redirects.

## Topic Area & Categories

Primary Track: AI/ML in Cloud
Secondary Track: Sovereign Cloud Infrastructure
Categories: Artificial Intelligence · Sovereign Cloud / GAIA-X · Bare-Metal Infrastructure · Edge Computing
Level: Intermediate–Advanced

## Your Profile

Name: Tobias Weiss
Email: tobias.weiss@ai-xr.de
Phone: [add]
Picture: [upload portrait — 1:1, ≥ 400px]
Role/Position: Cloud Architect & DevOps Engineer · AI Workload Specialist
LinkedIn: linkedin.com/in/tobias-weiss-ai-xr

### Bio

Tobias Weiss is a PhD in Business Informatics (Wirtschaftsinformatik) with a passion for Cloud, AI, and DevOps. He combines academic foundations with hands-on implementation: from infrastructure automation and cloud architecture to agentic AI workloads.

In his daily work he builds and operates sovereign cloud infrastructures — including an SCS-verified 3-node bare-metal K3s cluster (K3s + Ceph) on reused Huawei hardware, where he learned the hard way that architectures fail and pragmatically pivoted from OpenStack/OVN VMs to verified bare-metal. His motto: "Not macht erfinderisch" — necessity breeds invention; constraints are opportunities for clever solutions.

As an AI/AR/XR innovator and entrepreneur, he connects cloud infrastructure with the next generation of workloads such as openEduSuite — from research (tobias-weiss.org) and graph-based AI systems (graphwiz.ai) to practical AI literacy training (ki-kompetenz-training.org).

---

## AI Disclaimer

This proposal was drafted with the assistance of an AI coding agent (pi). All technical claims, bugs, and workarounds described were verified against the actual cluster runbook and reflect real production experience. The talk itself presents human-authored content; AI was used for drafting, structuring, and quality control of this submission.
