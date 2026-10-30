# executable/pyinstaller

Sets up Python (via `actions/python-setup/<package-manager>`) and builds a Windows executable with PyInstaller,
optionally zipping the bundle and uploading it as a workflow artifact.

- Runs on `windows-latest` only. PyInstaller does not cross-compile, so the action fails fast on any other OS.
- PyInstaller must be a dependency of your project (a `dev` group for uv/poetry, the manifest for pixi). It is run
  through the package manager, so the locked version is used.
- Attaching the zip to a GitHub release is out of scope (it needs `contents: write`, usually in another job). Use the
  `zip-path` output or the uploaded artifact in a follow-up job.

## Usage

```yaml
jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@<sha>
      - id: exe
        uses: Deltares-research/github-actions/actions/executable/pyinstaller@<sha>
        with:
          package-manager: poetry
          install-groups: dev
          name: singlerunner
          entry-point: src/singlerunner/rmm_single_runner_cli.py
          extra-args: --paths src --collect-all numpy --collect-all pandas --exclude-module pytest
          smoke-test: '"$EXECUTABLE" --help'
```

For anything non-trivial, commit a `.spec` file and pass `spec-file: app.spec` instead of `entry-point` and
`extra-args` (PyInstaller rejects those alongside a spec). `name` must match the name in the spec.

## Notes

- `extra-args` is split on whitespace with no quote handling. Relative paths in it resolve against the working
  directory. PyInstaller's default layout is onedir; pass `--onefile` for a single exe.
- The layout is detected from the build output: onedir gives `<output-dir>/<name>/` and sets `bundle-dir`, onefile
  gives `<output-dir>/<name>.exe` and leaves `bundle-dir` empty. A spec file works the same way.
- The zip is written next to `output-dir` and holds the bundle contents at its root.
- `--collect-data` / `--collect-all` inspect the *installed* package, so it must be installed in the environment.

## Outputs

`executable-path`, `bundle-dir`, `zip-path`, `artifact-name`.

See [`action.yml`](action.yml) for every input, and `.github/workflows/test.executable-pyinstaller.unit.yml` for tested
examples.
