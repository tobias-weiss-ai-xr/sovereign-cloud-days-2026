# Sovereign Cloud Days 2026 — Agentic AI meets Sovereign Cloud

Materials for **Sovereign Cloud Days 2026**:

> **Agentic AI meets Sovereign Cloud: openEduSuite on SCS-verified legacy bare-metal hardware**

A practical case study on running agentic AI workloads (openEduSuite) on a sovereign, SCS-verified bare-metal K3s cluster built from reused Huawei servers — *"Not macht erfinderisch"* (necessity breeds invention).

## Session

| | |
|---|---|
| **Format** | Interactive workshop · 60 min incl. Q&A (plus a 25 min talk submission) |
| **Slot** | Sun, 25.10.2026 · 11:15 · Workshop Stage |
| **Speaker** | Tobias Weiß · HRZ, Philipps-Universität Marburg |
| **Tracks** | AI/ML in Cloud (primary) · Sovereign Cloud Infrastructure (secondary) |

## Repository contents

| File | Description |
|---|---|
| `sovereign-cloud-days-2026-proposal.md` / `.txt` | Talk submission (25 min + 5 min Q&A): abstract, description, bio, topic area |
| `SCD-2026-openEduSuite-draft.md` | Workshop runbook / draft v1.1 — 60 min, interactive, with speaker notes |
| `SCD-2026-openEduSuite-slides.md` | Slide source — [Marp](https://marp.app/) Markdown, 16 slides, 16:9 |
| `SCD-2026-openEduSuite-slides.html` | Self-contained single-file HTML deck (inline SVG + screenshots) |
| `SCD-2026-openEduSuite-slides-marp.html` | Marp HTML render |
| `SCD-2026-openEduSuite-slides-marp.pdf` | Marp PDF export (16 pages) |
| `img/` | Cluster screenshots — iBMC/iMana, Grafana, ArgoCD, SCS compliance, Ceph, VLAN setup |
| `1780135484292.jpeg` | Speaker portrait (400×400, 1:1) |

## Rendering the slides

The Marp deck is generated from `SCD-2026-openEduSuite-slides.md`:

```bash
# HTML
marp --html SCD-2026-openEduSuite-slides.md -o SCD-2026-openEduSuite-slides-marp.html

# PDF — local screenshots in img/ require --allow-local-files
marp --html --pdf --allow-local-files SCD-2026-openEduSuite-slides.md -o SCD-2026-openEduSuite-slides-marp.pdf
```

Deck options (`marp: true`, `size: 16:9`, `paginate: true`, theme styles) live in the front-matter of the Markdown file.

## Hands-on

The workshop installs [pi](https://pi.dev) and runs first prompts against a free opencode model — **big pickle**:

```bash
curl -fsSL https://pi.dev/install.sh | sh   # or: npm i -g @earendil-works/pi-coding-agent  (Node 22.19+)
pi --version
```

Then `/login` → provider **opencode**, `/model` → **big pickle**.

## Notes

Slides and workshop material are in German; the talk proposal is in English. Technical claims reflect the cluster state as documented (2026-08); values only verifiable on the hardware are marked `[verify]`.

Drafted with the assistance of an AI coding agent (pi). The talk itself is human-authored.
