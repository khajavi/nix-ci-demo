# Hello World Scala with Reproducible Nix CI

A minimal Scala 3 project demonstrating reproducible builds using Nix flakes and GitHub Actions CI.

## Quick Start

### Prerequisites
- [Nix](https://nixos.org/download.html) with flakes support
- Or: Docker (to avoid Nix setup)

### Local Development

Enter the development environment:

```bash
nix develop
```

You're now in a shell with JDK 21 (use `nix develop .#jdk17` for JDK 17) and sbt pre-configured. The sbt launcher is fetched from nixpkgs, and it downloads the sbt version pinned in `project/build.properties` (1.9.8).

```bash
sbt compile     # Compile the project
sbt test        # Run tests
sbt +test       # Run tests on all cross-built Scala versions
sbt ++2.13.18 test  # Run tests on a specific Scala version
sbt 'run World' # Run the application with argument
sbt run         # Run with default "World" argument
```

### Without Nix (Docker)

```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  eclipse-temurin:21-jdk-jammy \
  bash -c "curl -L https://github.com/sbt/sbt/releases/download/v1.9.8/sbt-1.9.8.tgz | tar xz -C /opt && \
           export PATH=/opt/sbt/bin:\$PATH && \
           sbt test"
```

## Reproducibility Guarantees

This project pins:

- **JDK**: 21 (via nixpkgs 23.11)
- **sbt**: 1.9.8 (in `project/build.properties`)
- **Scala**: 3.3.8 default; cross-built for 2.13.18 and 3.3.8 (`crossScalaVersions` in `build.sbt`)
- **Nix packages**: Locked in `flake.lock`

Any developer (or CI) running `nix develop && sbt test` gets the **exact same environment** and dependency versions.

## File Structure

```
.
├── .github/workflows/ci.yml  # GitHub Actions CI workflow
├── flake.nix                 # Nix development environment
├── flake.lock                # Locked nix dependencies (commit this)
├── build.sbt                 # Scala build config
├── project/build.properties  # Pinned sbt version
├── project/plugins.sbt       # sbt plugins (scalafmt)
├── .scalafmt.conf            # scalafmt config
├── scripts/generate-ci.py    # Generates scripts/ci.sh from the CI workflow
├── scripts/hooks/pre-commit  # Regenerates scripts/ci.sh on commit
├── scripts/ci.sh             # Generated: runs the CI jobs locally (do not edit)
├── src/main/scala/com/example/
│   └── HelloWorld.scala      # Application code (package com.example)
└── src/test/scala/com/example/
    └── HelloWorldTest.scala  # Tests
```

## CI/CD

The workflow lives in `.github/workflows/ci.yml`. It runs on pushes and pull requests to `main`, and uses the same commands as local development via `nix develop`:

- **lint** job: formatting check.
- **test** job: a matrix over Scala versions (2.13.18, 3.3.8) × JDKs (17, 21), each running build, tests, and the app. Keep the Scala versions in sync with `crossScalaVersions` in `build.sbt`. The JDK entries map to the `jdk17` / `jdk21` dev shells in `flake.nix` (`nix develop .#jdk17`).

```yaml
nix develop --command bash -c "sbt scalafmtCheckAll scalafmtSbtCheck"
nix develop .#jdk17 --command bash -c "sbt '++2.13.18!' clean compile test"  # once per matrix entry
nix develop .#jdk17 --command bash -c "sbt '++2.13.18!' 'run World'"
```

This ensures **local dev and CI are identical**.

### Run CI locally

`scripts/ci.sh` runs the CI workflow's commands on your machine. It is generated from `.github/workflows/ci.yml`, so regenerate it after editing the workflow:

```bash
scripts/generate-ci.py   # .github/workflows/ci.yml -> scripts/ci.sh (needs python3 + PyYAML, both in `nix develop`)
scripts/ci.sh            # run all jobs
scripts/ci.sh lint       # run one job
```

`run:` steps become shell commands, `uses:` steps (checkout, Nix install) are skipped, and matrix jobs loop over every combination.

A pre-commit hook (`scripts/hooks/pre-commit`, enabled automatically by `nix develop` via `core.hooksPath`) regenerates and stages `scripts/ci.sh` whenever you commit a change to the workflow or the generator. Without Nix, enable it once with `git config core.hooksPath scripts/hooks`.

The `lint` job fails if `scripts/ci.sh` is out of date with the workflow, so commit the regenerated file together with workflow changes.

## Extending the Project

### Add a Dependency

```scala
// build.sbt
libraryDependencies ++= Seq(
  "dev.zio" %% "zio" % "2.0.20",
)
```

### Update Scala Version

Change the version vals in `build.sbt`:
```scala
val scala3 = "3.4.0"
```

Source must stay valid for every version in `crossScalaVersions`, so avoid Scala 3-only syntax (e.g. `@main`, braceless syntax) in `src/`.

### Add More Tools to Dev Environment

Edit `flake.nix`:
```nix
buildInputs = with pkgs; [
  jdk21
  sbt
  git
  scala  # Add this
];
```

Then restart: `exit` and `nix develop`.

## Useful Commands

```bash
# See what's locked in nix
nix flake show

# Update nix packages to latest in channel
nix flake update

# Run specific test
sbt 'testOnly *HelloWorldTest'

# Interactive Scala REPL
sbt console

# Format code (scalafmt, config in .scalafmt.conf)
sbt scalafmtAll scalafmtSbt

# Check formatting (as CI does)
sbt scalafmtCheckAll scalafmtSbtCheck
```

## Notes

- Commit `flake.lock` to ensure everyone has the same Nix package versions
- CI does not use a binary cache. To speed up builds, create a Cachix cache, add a `CACHIX_AUTH_TOKEN` repo secret, and add a `cachix/cachix-action` step to `.github/workflows/ci.yml`
