# SCD26 — Agentic AI meets Sovereign Cloud

Materials for **Sovereign Cloud Days 2026**:

> **Agentic AI meets Sovereign Cloud: openEduSuite on SCS-verified legacy bare-metal hardware**

A practical case study on running agentic AI workloads (openEduSuite) on a sovereign, SCS-verified bare-metal K3s cluster built from reused Huawei servers — *"Not macht erfinderisch"* (necessity breeds invention).

<p align="center">
  <img src="slides/img/hero-agentic-scs.svg" alt="Agentic AI on Sovereign Cloud — Model · Harness · Loop → Sovereign Cloud" width="700" />
</p>

## Session

| | |
|---|---|
| **Format** | Talk with workshop elements · 60 min incl. Q&A |
| **Slot** | Sun, 25.10.2026 · 11:15 · Workshop Stage |
| **Speaker** | Tobias Weiß · tobias@tobias-weiss.org |
| **Tags** | AI Infrastructure · Kubernetes & Cloud Native · Sovereign Cloud Stack |



See `AGENTS.md` for repository structure and Marp rendering instructions.

## Hands-on

The workshop element installs [opencode](https://opencode.ai) and runs first prompts against a free **OpenCode Zen** model — **Big Pickle** (stealth, free) or **Beam Free** (Reflection's open-weight 501B model, 1M-token context, no training on your data):

```bash
curl -fsSL https://opencode.ai/install | bash   # or: npm install -g opencode-ai
opencode --version
```

Then `/connect` → **OpenCode Zen** → pick **Big Pickle** or **Beam Free** from the free model list. Switch models with `/models`.

> ⚠️ **Privacy:** Big Pickle's provider may train on your input; Beam Free does not (retains data 30 days for safety). **Never paste private, customer, or unpublished data into a model that trains on user input.** For sensitive work, run a local model (Ollama, `ollama run beam`) or your own sovereign endpoint. If `opencode.ai` does not resolve on the workshop network, set DNS to `1.1.1.1` / `8.8.8.8` or add a hosts entry (`dig +short opencode.ai @1.1.1.1`, then `<IP> opencode.ai` in `/etc/hosts`; verified 19 Oct 2026: `172.65.90.20`).

## Notes

Slides are in English. Technical claims reflect the cluster state as documented (2026-08); values only verifiable on the hardware are marked `[verify]`.

Drafted with the assistance of an AI coding agent. The talk itself is human-authored.
