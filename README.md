# Hello World Scala with Reproducible Nix CI

A minimal Scala 3 project demonstrating reproducible builds using Nix flakes and GitHub Actions CI.

## Quick Start

### Prerequisites
- [Nix](https://nixos.org/download.html) with flakes support
- Or: Docker (to avoid Nix setup)

### Local Development

Enter the development environment:

```bash
nix flake update  # Lock versions (first time)
nix develop
```

You're now in a shell with JDK 21 and sbt 1.9.8 pre-configured.

```bash
sbt compile     # Compile the project
sbt test        # Run tests
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
- **Scala**: 3.3.1 (in `build.sbt`)
- **Dependencies**: Managed by sbt's `sbt.lock` (when running `sbt update`)
- **Nix packages**: Locked in `flake.lock`

Any developer (or CI) running `nix develop && sbt test` gets the **exact same environment** and dependency versions.

## File Structure

```
.
├── flake.nix                 # Nix development environment
├── flake.lock                # Locked nix dependencies (commit this)
├── build.sbt                 # Scala build config
├── project/build.properties  # Pinned sbt version
├── src/main/scala/           # Application code
└── src/test/scala/           # Tests
```

## CI/CD

GitHub Actions runs the same commands locally via `nix develop`:

```yaml
nix develop --command bash -c "sbt clean compile test"
```

This ensures **local dev and CI are identical**.

## Extending the Project

### Add a Dependency

```scala
// build.sbt
libraryDependencies ++= Seq(
  "dev.zio" %% "zio" % "2.0.20",
)
```

Then:
```bash
sbt update  # Creates/updates sbt.lock
git add sbt.lock
```

### Update Scala Version

Change in `build.sbt`:
```scala
ThisBuild / scalaVersion := "3.4.0"
```

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

# Format code
sbt 'scalafmt'
```

## Notes

- Commit `flake.lock` and `sbt.lock` to ensure everyone has the same versions
- Use Cachix for faster CI builds if you set up a cache (optional)
- The workflow assumes a private Cachix cache; remove the cachix-action step if you don't use it
