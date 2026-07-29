# Contributing to NeuralCompliance.jl

Thank you for considering a contribution. This project underpins
compliance tooling that may be used in regulated-industry deployments,
so we hold changes to a high bar for correctness, test coverage, and
documentation.

## Development setup

```bash
git clone https://github.com/neuralcompliance/NeuralCompliance.jl
cd NeuralCompliance.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Run the test suite:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Build the documentation locally:

```bash
julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

## Code style

This project uses [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl)
with the `blue` style (see `.JuliaFormatter.toml`). Before committing:

```bash
julia -e 'using Pkg; Pkg.add("JuliaFormatter"); using JuliaFormatter; format(".")'
```

CI will reject unformatted code.

## Pull request expectations

1. **Every new public function needs a docstring** with an `# Arguments`
   or equivalent explanation, and should be added to `docs/src/api.md`
   if user-facing.
2. **Every new feature needs tests** in the corresponding `test/test_*.jl`
   file. We do not merge untested validation logic — this is a
   compliance library; correctness bugs here have outsized real-world
   consequences.
3. **Soundness claims must be justified.** If you add a new bound-propagation
   rule or constraint type, include a short comment or doc note on *why*
   it is sound (or clearly mark it as a heuristic/empirical method if it
   is not).
4. **No new required dependencies** without discussion in an issue first.
   Keeping the dependency surface minimal is a deliberate design goal —
   see the README's "Design Philosophy" section.

## Reporting issues

Please include:
- Julia version (`versioninfo()`)
- A minimal reproducible example
- Expected vs. actual behavior

For suspected soundness bugs in the interval bound propagation logic
(i.e. cases where a certified bound does *not* actually contain the
true output), please mark the issue `soundness-bug` — these are
treated as highest priority.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
