# AGENTS.md — sovereign-cloud-days-2026

## Repository structure

```
sovereign-cloud-days-2026/
├── README.md
├── AGENTS.md
├── compliance/                # SCS/compliance source docs + dashboard
├── self-assessment/           # EU Cloud Sovereignty self-assessment
│   ├── EU-sovereignty-assessment.md
│   └── self-assessment-score.js
├── slides/                    # slide deck (source + renders + screenshots)
│   ├── SCD-2026-openEduSuite-slides.md       # Marp Markdown source
│   ├── SCD-2026-openEduSuite-slides.html     # legacy self-contained HTML deck
│   ├── SCD-2026-openEduSuite-slides-marp.html
│   ├── SCD-2026-openEduSuite-slides-marp.pdf
│   └── img/
└── .gitignore
```

## Rendering the slides (Marp)

Source: `slides/SCD-2026-openEduSuite-slides.md` (Marp Markdown, 16:9).

```bash
# HTML
marp --html slides/SCD-2026-openEduSuite-slides.md -o slides/SCD-2026-openEduSuite-slides-marp.html

# PDF — local screenshots in slides/img/ require --allow-local-files
marp --html --pdf --allow-local-files slides/SCD-2026-openEduSuite-slides.md -o slides/SCD-2026-openEduSuite-slides-marp.pdf
```

Deck options (`marp: true`, `size: 16:9`, `paginate: true`, theme styles) live in the front-matter of the Markdown file. Regenerate the HTML/PDF renders after editing the source.
