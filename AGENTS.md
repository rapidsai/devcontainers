# Agent Instructions

## Feature versions

When modifying an existing feature under `features/src/<feature>/`, increment the patch component of that feature's `devcontainer-feature.json` version in the same pull request. Increment it once per feature per pull request, regardless of how many files or commits modify the feature.

Before selecting the new version, update the branch with `main` and increment from the version currently on `main`, not from the branch's original base.
