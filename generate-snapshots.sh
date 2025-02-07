#!/usr/bin/env sh

set -euxo pipefail

unset FORGE_GAS_REPORT
unset FOUNDRY_PROFILE
unset FOUNDRY_VIA_IR
unset FORGE_SNAPSHOT_EMIT

export FORGE_SNAPSHOT_CHECK='false'

mkdir -p coverage
export FORGE_SNAPSHOT_EMIT='false'
forge coverage --force --report-file coverage/lcov.info --report lcov --report summary --no-match-path "test/comparison/*" --no-match-coverage "test/comparison/*"
rm snapshots/*.json # rm after FORGE_SNAPSHOT_EMIT supported

for test_profile in no-ir via-ir; do
  export FOUNDRY_PROFILE=test-$test_profile
  mkdir -p snapshots/$test_profile
  export FORGE_SNAPSHOT_EMIT='true'
  touch snapshots/$test_profile/comparison.gas-snapshot # rm after FORGE_SNAPSHOT_EMIT supported
  forge snapshot --force --snap snapshots/$test_profile/comparison.gas-snapshot --match-path "test/comparison/*"
  forge test --force -vvv --no-match-path "test/comparison/*"
done
