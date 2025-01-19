// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

const ONE_GWEI: bigint = parseEther("0.001");

const TestFixtureModule = buildModule("TestFixtureModule", (m) => {
  const lockedAmount = m.getParameter("lockedAmount", ONE_GWEI);

  const reader = m.contract("Test", [], {
    value: lockedAmount,
  });

  return {  reader };
});

export default TestFixtureModule;
