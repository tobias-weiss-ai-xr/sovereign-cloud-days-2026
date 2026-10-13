# EU Cloud Sovereignty Self-Assessment — openEduSuite SCS-Cluster

Eigeneinstufung des Stacks (openEduSuite auf SCS-verified bare-metal K3s, HRZ
Marburg) gegen das **EU Cloud Sovereignty Framework** (v1.2.1) inkl. offizieller
Scoring-Methodik des *Implementation Guidance + Sovereignty Assessment
Calculator* (1. Juli 2026).

Bewertungswerkzeug: <https://flavienbwk.github.io/cloud-sovereignty-score/>

## Ergebnis

| Metrik | Wert |
|---|---|
| **Sovereignty Score** (gewichtet, /1000) | **73.5 %** (735/1000) |
| **SEAL** (Weakest-Link, 0–4) | **SEAL-1 — Jurisdictional Sovereignty** |

> Ein hoher Score garantiert **keinen** hohen SEAL: SEAL = Minimum über *alle*
> 48 Kriterien. Ein einziges nicht-souveränes Kriterium (non-EU-Hardware)
> deckelt den SEAL, auch wenn Strategie/Technik stark sind.

## Breakdown nach Objective

| Objective | Gewicht | Score | Objective-SEAL |
|---|---|---|---|
| SOV-1 Strategic Sovereignty | 20 % | 94 % | SEAL-4 |
| SOV-4 Operational Sovereignty | 15 % | 83 % | SEAL-3 |
| SOV-6 Technology Sovereignty | 15 % | 80 % | SEAL-3 |
| SOV-3 Data & AI Sovereignty | 10 % | 75 % | SEAL-1 |
| SOV-2 Legal & Jurisdictional | 10 % | 71 % | SEAL-1 |
| SOV-7 Security & Compliance | 15 % | 64 % | SEAL-1 |
| SOV-5 Supply Chain Sovereignty | 10 % | 50 % | SEAL-1 |
| SOV-8 Environmental Sustainability | 5 % | 19 % | SEAL-1 |

## Binding criteria (definieren den SEAL = 1)

- **SOV-2 Q2 Extraterritoriale Gesetze:** Huawei-/Intel-Hardware → Belastung
  durch non-EU-Jurisdiktionen bleibt (nur Mitigationsklauseln).
- **SOV-3 Q3 Sichere Löschung:** Lösch-Nachweis nur intern (Policies), kein
  unabhängig verifizierter Beleg.
- **SOV-5 Q1/Q2 Lieferkette:** Komponenten/Einbau non-EU (China/US), nur
  teilweise offengelegt.
- **SOV-7 Q1 Zertifizierung:** keine formale EAL-Zertifizierung (SCS-Tests ≠ EAL).
- **SOV-7 Q7 Auditierbarkeit:** unabhängige Audits möglich, aber nicht vollständig.
- **SOV-8 Q1/Q3 Energie:** keine PUE-/Emissionsberichte.

## Hebel auf SEAL ≥ 3

1. **Supply Chain (SOV-5):** Herkunftsnachweise/EU-fabrizierte Plattform,
   offengelegte Firmware; hardware ist der größte Einzelhebel.
2. **Zertifizierung (SOV-7 Q1):** formale EAL-Zertifizierung anstreben.
3. **Energie (SOV-8):** PUE-Messung, emissionsbericht (CSRD), EU-Grünstrom.

## Repro

Antwort-Mapping (48 Kriterien) und Rechenlogik: `self-assessment-score.js`.
Datenquellen `questions.js` + `app.js` aus <https://github.com/flavienbwk/cloud-sovereignty-score>.

*Selbsteinschätzung, Draft — keine offizielle EU-Zertifizierung. Bewusst ehrlich
(bindungskritische non-EU-Hardware wird nicht schöngeredet), konsistent mit dem
„ehrlichen Lücken-Reporting“ des Talks.*