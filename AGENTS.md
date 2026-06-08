# Agent Instructions

## Start Here

- Before doing any project work, read `CONTEXT.md`.
- Treat `CONTEXT.md` as the source of truth for project terminology, current systems, known gaps, and contributor guidance.
- If code and `CONTEXT.md` disagree, inspect the code, call out the mismatch, and update the plan before changing behavior.

## Development Expectations

- Keep changes aligned with the project language in `CONTEXT.md`.
- Prefer small, focused edits that match the existing Godot scene and script ownership boundaries.
- When a project feature is completed, update `CONTEXT.md` so the handbook reflects the new behavior, terminology, systems, or known gaps.
- Do not treat temporary scene files, such as `player.tscn*.tmp`, as canonical project files.
- Preserve unrelated user changes. Do not revert or clean up files outside the requested scope.

## Tests

- Add or update unit tests for new features when the project has a viable test path for the touched system.
- For behavior changes, include focused tests that cover the expected path and at least one relevant edge case.
- If a feature cannot reasonably be unit tested in the current Godot setup, document the reason and provide a manual verification path.
- Run the relevant tests or checks before handing work back. If they cannot be run, state why.
- On this machine, use `GODOT_BIN=C:\Users\walid\OneDrive\Bureau\Professional Folder\Gdquest\Godot_v4.6.1-stable_win64.exe` when running `scripts/run_gut_tests.ps1`.

## Large Feature Review

- For big features, run the `$thermo-nuclear-code-quality-review` skill before finalizing the work.
- Use that review to catch structural regressions, large-file growth, spaghetti branching, weak abstractions, and missed simplifications.
- Do not run the thermo-nuclear review for small fixes, documentation-only edits, or narrow asset/config changes unless the user explicitly asks for it.
