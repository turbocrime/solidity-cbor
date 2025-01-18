#!/usr/bin/env sh

set -euxo pipefail

unset FORGE_GAS_REPORT
unset FOUNDRY_PROFILE
unset FOUNDRY_VIA_IR

mkdir -p coverage
forge coverage --force --report-file coverage/lcov.info --report lcov --report summary --no-match-path "test/comparison/*" --no-match-coverage "test/comparison/*"

for test_profile in no-ir via-ir; do
  export FOUNDRY_PROFILE=test-$test_profile
  mkdir -p snapshots/$test_profile
  forge snapshot --force --snap snapshots/$test_profile/.gas-snapshot --match-path "test/comparison/*"
  forge test --force -vvv --no-match-path "test/comparison/*"
done
