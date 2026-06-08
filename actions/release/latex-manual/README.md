# LaTeX Manual Action

Self-contained composite action that builds Deltares LaTeX/PDF manuals via the
[`ddocs`](https://github.com/Deltares-research/doc_utils) CLI. It installs its own Python and `ddocs` (with
pandoc bundled through `pypandoc-binary`), fetches the Deltares LaTeX styles, optionally converts Markdown to
LaTeX, installs TeX Live (cached across runs), compiles the PDFs, uploads them as an artifact, and can attach
them to a GitHub release.

It does **not** touch the consumer's `pyproject.toml`, lock file, or virtualenv — it is an isolated
documentation pipeline. It targets **GitHub-hosted Linux runners** (uses `apt` + `sudo`).

## How it works

Steps run in this order; PDF-related steps are skipped when `tex-files` is empty.

| Step | What it does |
|---|---|
| Require token | Fails immediately if `latex-template-token` is empty (avoids a confusing `*.sty not found` later). |
| Install ddocs | `pip install` the pinned `ddocs` (its `pypandoc-binary` dep provides pandoc — no apt pandoc). |
| Fetch styles | `ddocs get-tex-template` clones the internal `Deltares/LatexInstallation` repo into the output dir. A fetch failure is a warning, not a hard error. |
| Convert Markdown | `ddocs markdown-to-latex` (skipped when `markdown-input-dir` is empty). |
| Install LaTeX | `ddocs pdflatex download --backend apt`, with the installed TeX Live tree cached (see [Caching](#caching)). Only when `tex-files` is set. |
| Compile PDFs | For each `tex-files` entry: pdflatex → bibtex (if the doc cites) → two more pdflatex passes. |
| Upload artifact | Uploads `*.pdf` from the output dir as the `LaTeX-Documentation` artifact. |
| Upload to release | Attaches the PDFs to a release (see [Release upload](#release-upload)). |

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `python-version` | no | `3.12` | Python to install. `ddocs` requires ≥ 3.11. |
| `tex-files` | no | `''` | Comma-separated `.tex` files (without extension) to compile. **Empty = convert only, skip TeX Live + pdflatex.** |
| `markdown-input-dir` | no | `docs/mkdocs/user_docs` | Markdown input dir. **Set to `''` to skip conversion** (repos that author LaTeX directly). |
| `latex-output-dir` | no | `docs/end-user-docs/source` | Where styles are fetched and `.tex`/`.pdf` live. |
| `latex-template-token` | **yes** | — | Token with **read access to the internal `Deltares/LatexInstallation`** repo. The default `GITHUB_TOKEN` is scoped to the caller's own repo and will **not** work — supply a PAT or GitHub App token. The action fails fast if empty. |
| `upload-to-release` | no | `true` | Whether to attach the PDFs to a GitHub release. |
| `release-tag` | no | `''` | Existing release tag to attach to, regardless of event (use from a `workflow_run` after a release). Empty → taken from the `release` event payload. |
| `github-token` | no | `''` | Token used for the release upload (`contents: write`). |

## Required workflow setup

```yaml
permissions:
  contents: write   # only needed if attaching PDFs to a release

steps:
  - uses: actions/checkout@v4
```

You must provide **`latex-template-token`** — a secret with read access to `Deltares/LatexInstallation`
(typically an org secret, e.g. `LATEX_TEMPLATE_TOKEN`). Without it the build fails fast.

## Caching

- **TeX Live** — the installed system tree (binaries, libs, generated formats, alternatives symlinks) is
  packed into a user-owned tarball and restored on later runs, replacing the ~2-3 min `apt` install with a
  ~20 s extract. The cache key includes the runner image family, so a major image bump invalidates it
  automatically. The cache is per-repository and GitHub evicts entries unused for 7 days.
- **pip** — `~/.cache/pip` is cached (keyed on the `ddocs` pin) so `ddocs` and its deps aren't re-downloaded.

## Release upload

`github.event_name` is **not** required to be `release`. The action uploads when `tex-files` is set,
`upload-to-release` is `true`, `github-token` is non-empty, and a tag is resolved:

- `release-tag` input wins when set (the **`workflow_run`-after-release** pattern — a release made with
  `GITHUB_TOKEN` does not fire a `release` event, so you pass the tag explicitly).
- Otherwise the tag comes from the `release` event payload.

On other events (manual dispatch, PR) the PDFs are still produced as the `LaTeX-Documentation` artifact.

## Examples

### 1. Build on demand / PR (artifact only)

```yaml
on:
  workflow_dispatch:
  pull_request:
    paths: ['docs/end-user-docs/**']

jobs:
  build-manuals:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Deltares-research/github-actions/actions/release/latex-manual@latex/v1
        with:
          markdown-input-dir: ''     # pure-LaTeX manual; skip conversion
          latex-output-dir: docs/end-user-docs
          tex-files: my_usermanual,my_techref
          latex-template-token: ${{ secrets.LATEX_TEMPLATE_TOKEN }}
```

### 2. Attach PDFs to a release (via `workflow_run` after the release workflow)

A release created with `GITHUB_TOKEN` does not fire a `release` event, so trigger off the release workflow
and pass the resolved tag via `release-tag`:

```yaml
on:
  workflow_run:
    workflows: ["Automated release workflow"]
    types: [completed]

jobs:
  build-manuals:
    if: github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Resolve release tag
        id: rel
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: echo "tag=$(gh api repos/${{ github.repository }}/releases --jq '.[0].tag_name')" >> "$GITHUB_OUTPUT"
      - uses: actions/checkout@v4
        with:
          ref: ${{ steps.rel.outputs.tag }}
      - uses: Deltares-research/github-actions/actions/release/latex-manual@latex/v1
        with:
          markdown-input-dir: ''
          latex-output-dir: docs/end-user-docs
          tex-files: my_usermanual,my_techref
          latex-template-token: ${{ secrets.LATEX_TEMPLATE_TOKEN }}
          release-tag: ${{ steps.rel.outputs.tag }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### 3. Markdown → LaTeX → PDF

```yaml
- uses: Deltares-research/github-actions/actions/release/latex-manual@latex/v1
  with:
    markdown-input-dir: docs/mkdocs/user_docs   # ddocs converts *.md → *.tex
    latex-output-dir: docs/end-user-docs/source
    tex-files: manual
    latex-template-token: ${{ secrets.LATEX_TEMPLATE_TOKEN }}
```

## Notes

- **Linux only** — relies on `apt`/`sudo` and `/usr/lib/x86_64-linux-gnu`. Not for Windows/macOS or
  non-Debian self-hosted runners.
- **bibtex, not biber** — the compile loop runs `bibtex`; the Deltares classes use `biblatex` with
  `backend=bibtex`. `biber` is not installed.
- **ddocs is pinned** to a commit (the `0.2.0` release) via the single `DDOCS_REPO` constant in `action.yml`;
  bump that to upgrade.
- Pin the action against the commit SHA behind `latex/v1` for security scanners — see the
  [repo README releases table](../../../README.md#latest-releases).
