#!/usr/bin/env sh

set -euxo pipefail

unset FORGE_GAS_REPORT
unset FOUNDRY_PROFILE
unset FOUNDRY_VIA_IR

for test_profile in test-no-ir test-via-ir; do
  export FOUNDRY_PROFILE=$test_profile
  forge coverage --force --report-file $test_profile.lcov.info --report lcov --report summary --no-match-path "test/comparison/*" --no-match-coverage "test/comparison/*"
  forge snapshot --force --snap $test_profile.gas-snapshot --match-path "test/comparison/*"
  forge test --force -vvv --no-match-path "test/comparison/*"
done
