# Contributing

Thanks for improving materials for the UofT ASIC Team.

## After creating a course from this template

1. Run `scripts/init-template.py` with `--id`, `--title`, and `--description` (org is always `uoftasic`).
2. Enable GitHub Pages with **Settings → Pages → Source: GitHub Actions**. `.github/workflows/site.yml` then builds `docs/` with Quarto and deploys it.
3. Prefer repo names that match course ids (`dd103`, `ic101`, …).

See [TEMPLATE.md](TEMPLATE.md).

## Placeholders

Only these three are fillable:

| Token | Example |
|-------|---------|
| `dd102` | `dd103` |
| `DD102 — Digital Logic & FPGAs` | `DD103 — RTL on FPGAs & ASICs` |
| `Draw a circuit, transcribe it to SystemVerilog, and run it on an FPGA.` | `RTL synthesis intro with Yosys` |

## Conventions

| Item | Convention |
|------|------------|
| Org | `uoftasic` |
| Default branch | `main` |
| Docs pages | kebab-case `.md` under `docs/` |
| Lab IDs | `lab-NN-short-name` |
| Adding a guide page | add `.md` under `docs/guide/` (reading only, no required commands), add it to a Read row of the Course path in `docs/index.md`, add it to the sidebar in `docs/_quarto.yml` and the chapters in `docs/_quarto-pdf.yml` in the same order |
| Adding a lab | `labs/<id>/` + `docs/labs/<id>-overview.md` + a Do row in the Course path + sidebar entry in `docs/_quarto.yml` + chapter in `docs/_quarto-pdf.yml`, in the same order |
| Links between pages | relative to the page they are written in (`../guide/x.md` from a lab); GitHub URLs for `labs/` and `scripts/` |
| Course path rows | columns `\| # \| \| What \| Time \|`; plain Read / Do; Do rows are `[Lab NN: Title](labs/...)` plus one sentence on what the student does; row times add up to the course total on the home page |
| Lab titles | `# Lab NN: Title` in the writeup, and the same text in the sidebar and the Course path |
| Binaries | small images in `docs/assets/`; large data → Git LFS or external |

## Docs vs labs

- `docs/`: the published site. Guide pages in `docs/guide/` are for reading; lab writeups in `docs/labs/` are where students run things, as numbered steps. Each writeup ends with Finishing (You're done when, Questions with collapsed answers, Submit), then Going further (optional), then the "Next on the Course path" line. Reference numbers and troubleshooting tables go on `docs/reference/expected-results.md`.
- `labs/`: runnable HDL, Python and data. Each `labs/<id>/README.md` links to its writeup on the site and stays short: how to run, the make targets, the file list.
- `scripts/`: utilities; list entry points in `scripts/README.md`.

Do not put grades, solution keys, or PII under `docs/`. Prefer `labs/**/solutions/` and gitignore them on student forks when needed.

## Local docs preview

```bash
quarto preview docs                            # -> http://localhost:4200
quarto render docs --profile pdf --to typst    # whole course as one PDF in docs/_book/
```

## Pull requests

Keep changes focused. For doc-only PRs, check the navigation and math in the local preview when you can. CI checks links on every pull request that touches `docs/**`: `.github/workflows/site.yml` renders the site and runs `scripts/check_site.py` on every local link and anchor, and `.github/workflows/docs-link-check.yml` runs lychee on the Markdown and checks that every image a page references exists.
