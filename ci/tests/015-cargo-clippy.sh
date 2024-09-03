#!/bin/bash
# shellcheck disable=SC2086
set -eo pipefail

cd "${RUST_SUBFOLDER}" || exit

# Running cargo fmt
echo "" && echo "=== Running cargo clippy ===" && echo ""
env -u RUSTFLAGS cargo $CARGOARGS clippy  -- --deny warnings