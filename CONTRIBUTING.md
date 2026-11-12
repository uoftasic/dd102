# Contributing

Thanks for improving materials for the UofT ASIC Team.

## After creating a course from this template

1. Run `scripts/init-template.py` with `--id`, `--title`, and `--description` (org is always `uoftasic`).
2. Enable GitHub Pages: branch `main`, folder `/docs`.
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
| Adding a guide page | add `.md` under `docs/guide/` (reading only, no required commands), add it to a Read row of the Course path in `docs/README.md`, link it in `docs/_sidebar.md` in the same order |
| Adding a lab | `labs/<id>/` + `docs/labs/<id>-overview.md` + a Do row in the Course path + sidebar entry in the same order |
| Course path rows | columns `\| # \| \| What \| Time \|`; plain Read / Do; Do rows are `[Lab NN: Title](labs/...)` plus one sentence on what the student does; row times add up to the course total on the home page |
| Lab titles | `# Lab NN: Title` in the writeup, and the same text in the sidebar and the Course path |
| Binaries | small images in `docs/assets/`; large data → Git LFS or external |

## Docs vs labs

- `docs/`: the published site. Guide pages in `docs/guide/` are for reading; lab writeups in `docs/labs/` are where students run things, as numbered steps. Each writeup ends with Finishing (You're done when, Questions with collapsed answers, Submit), then Going further (optional), then the "Next on the Course path" line. Reference numbers and troubleshooting tables go on `docs/reference/expected-results.md`.
- `labs/`: runnable HDL, Python and data. Each `labs/<id>/README.md` links to its Docsify writeup and stays short: how to run, the make targets, the file list.
- `scripts/`: utilities; list entry points in `scripts/README.md`.

Do not put grades, solution keys, or PII under `docs/`. Prefer `labs/**/solutions/` and gitignore them on student forks when needed.

## Local docs preview

```bash
npx docsify-cli serve docs
```

## Pull requests

Keep changes focused. For doc-only PRs, check navigation and math locally when practical. Optional CI may link-check `docs/**`.
