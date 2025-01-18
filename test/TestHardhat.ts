import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseGwei } from "viem";

describe("TestHardhat", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployReadThisFixture() {
    const lockedAmount = parseGwei("1");

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const reader = await hre.viem.deployContract("TestHardhat", [], {
      value: lockedAmount,
    });

    const publicClient = await hre.viem.getPublicClient();

    return {
      reader,
      lockedAmount,
      owner,
      otherAccount,
      publicClient,
    };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { reader, owner } = await loadFixture(deployReadThisFixture);

      expect(await reader.read.owner()).to.equal(
        getAddress(owner.account.address),
      );
    });

    it("Should receive and store the funds to lock", async function () {
      const { reader, lockedAmount, publicClient } = await loadFixture(
        deployReadThisFixture,
      );

      expect(
        await publicClient.getBalance({
          address: reader.address,
        }),
      ).to.equal(lockedAmount);
    });
  });

  describe("Parsing", function () {
    describe("Validations", function () {
      it("Should revert with the right error if called from another account", async function () {
        const { reader, otherAccount } = await loadFixture(
          deployReadThisFixture,
        );

        // We retrieve the contract with a different account to send a transaction
        const readerAsOtherAccount = await hre.viem.getContractAt(
          "TestHardhat",
          reader.address,
          { client: { wallet: otherAccount } },
        );
        await expect(
          readerAsOtherAccount.write.readThis([`0x421312`]),
        ).to.be.rejectedWith("You aren't the owner");
      });

      it("Shouldn't fail to parse bytes", async function () {
        const { reader } = await loadFixture(deployReadThisFixture);

        await expect(reader.write.readThis([`0x421312`])).to.be.fulfilled;
      });
    });

    describe("Events", function () {
      it("Should emit an event on parsing bytes", async function () {
        const { reader, publicClient } = await loadFixture(
          deployReadThisFixture,
        );

        const hash = await reader.write.readThis([`0x421312`]);
        await publicClient.waitForTransactionReceipt({ hash });

        // get the withdrawal events in the latest block
        const withdrawalEvents = await reader.getEvents.ParsedBytes32();
        expect(withdrawalEvents).to.have.lengthOf(1);
        expect(withdrawalEvents[0].args.item).to.equal(
          `0x1312000000000000000000000000000000000000000000000000000000000000`,
        );
      });
    });
  });
});
