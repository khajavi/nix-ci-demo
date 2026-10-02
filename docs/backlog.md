# Backlog

## Run CI locally without Docker

### Context

`scripts/ci.sh` is generated from `.github/workflows/ci.yml` by `scripts/generate-ci.py`. It matches CI on pass/fail behavior, but it differs from a GitHub run in two ways:

- **It is sequential.** CI runs `lint` and the four `test` matrix entries (Scala 2.13.18 / 3.3.8 × JDK 17 / 21) at the same time, each on its own runner. `ci.sh` runs them one after another, so a local run takes about 5× the wall time.
- **It ignores concurrency settings.** The generator reads only `run`, `strategy.matrix` and `name`. If someone adds `needs:`, `max-parallel` or a `concurrency:` group to the workflow, `ci.sh` silently ignores them, and the sync check in `lint` cannot detect it because the regenerated script comes out identical.

[`act`](https://github.com/nektos/act) is the usual way to run a workflow locally. It needs Docker by default. Its host mode (`-P ubuntu-24.04=-self-hosted`) avoids Docker but is a poor fit here (see "Why not `act` host mode").

### Proposal

#### 1. Fail loudly on unsupported workflow keys

Make `scripts/generate-ci.py` exit with an error when the workflow uses a key it does not model:

- `needs` (job dependencies)
- `strategy.max-parallel`
- `concurrency` (workflow level or job level)

Error messages should name the key and the job, as the generator already does for unsupported `${{ }}` expressions and matrix `include` / `exclude`. This keeps `ci.sh` from drifting from the workflow without anyone noticing.

Acceptance criteria:

- Adding any of the keys above to `ci.yml` makes `scripts/generate-ci.py` fail with a clear message.
- The pre-commit hook and the `lint` sync check fail accordingly.
- The current workflow still generates the same `ci.sh`.

#### 2. Add a `--parallel` flag to `scripts/ci.sh`

Run each matrix combination in its own temporary copy of the repo, in the background, and wait for all of them:

```bash
scripts/ci.sh --parallel          # all jobs, concurrently
scripts/ci.sh --parallel test     # only the test matrix, concurrently
```

Design notes:

- **Isolation:** create one `git worktree` (or `rsync` copy) per combination. All combinations currently share one `target/` and every run starts with `sbt clean`, so running them in the same tree would overwrite each other's output. CI avoids this because each job has its own runner and checkout.
- **Uncommitted changes:** a worktree only has committed files. Either copy the working tree (`rsync`, excluding `.git` and `target/`) or document that `--parallel` tests committed state. Prefer `rsync` so local edits are tested.
- **Output:** prefix or buffer each combination's output so concurrent logs do not interleave. Print a per-combination pass/fail summary at the end.
- **Failure behavior:** keep `fail-fast: false` semantics. One failure does not stop the others, and the script exits non-zero if any combination failed.
- **Cleanup:** remove the temporary copies on exit, including on Ctrl-C (`trap`).
- **Concurrency limit:** default to the number of CPUs, with an override such as `--jobs N`. Respect `max-parallel` if the generator later supports it.
- **Generator change:** emit the parallel runner from `generate-ci.py`. `ci.sh` is generated, so do not hand-edit it.

Acceptance criteria:

- `scripts/ci.sh --parallel` produces the same pass/fail result as the sequential run.
- Wall time for the four-entry matrix is close to the slowest single entry, not the sum.
- No temporary directories remain after a normal run, a failing run, or an interrupt.
- The sync check still passes after regenerating.

### Why not `act` host mode

`act` host mode (`-P ubuntu-24.04=-self-hosted`) was considered and not adopted. It has not been run on this repo; the points below come from reading the workflow and `act`'s options.

- `cachix/install-nix-action` would run the Nix installer on the developer's real machine. It would have to be skipped locally with `if: ${{ !env.ACT }}` guards in the workflow.
- `actions/checkout` needs `node` on the host, or also has to be guarded.
- There is no per-job filesystem isolation, so parallel matrix jobs running `sbt clean` in one tree can conflict. Whether `act` creates separate workspaces in host mode is untested. If it does not, `--concurrent-jobs 1` is no better than `ci.sh`.
- Steps run as the developer's user with no container boundary.
- The `act` in nixpkgs (0.2.82) prints a warning that it is vulnerable to CVE-2026-34041 and CVE-2026-34042 and recommends 0.2.86 or later. Use a newer build if `act` is used at all.

### Order

Do item 1 first. It is small and removes the silent-drift risk. Item 2 is optional and only worth doing if the local run time becomes a problem.
