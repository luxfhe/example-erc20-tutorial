import { expect } from "chai";
import hre, { ethers } from 'hardhat';

/**
 * Basic tests for WrappingERC20 contract
 *
 * Note: Full FHE operations (wrap, unwrap, transferEncrypted) require a LuxFHE network
 * with the FHE TaskManager precompile deployed. These tests verify:
 * 1. Contract deployment and basic ERC20 functionality
 * 2. Public token operations work correctly
 *
 * For full integration tests with FHE, use: npx hardhat test --network localluxfhe
 */
describe('Test WrappingERC20', () => {
  let contract: any;
  let owner: any;
  let recipient: any;

  beforeEach(async () => {
    const [signer, dest] = await ethers.getSigners();
    owner = signer;
    recipient = dest;

    const WrappingERC20 = await ethers.getContractFactory("WrappingERC20");
    contract = await WrappingERC20.deploy("Test Token", "TST");
    await contract.waitForDeployment();
  });

  describe('Deployment', () => {
    it('Should deploy with correct name and symbol', async () => {
      expect(await contract.name()).to.equal("Test Token");
      expect(await contract.symbol()).to.equal("TST");
    });

    it('Should deploy with initial supply to owner', async () => {
      const balance = await contract.balanceOf(owner.address);
      // 100 tokens with 18 decimals
      expect(balance).to.equal(100n * 10n ** 18n);
    });

    it('Should have 18 decimals', async () => {
      expect(await contract.decimals()).to.equal(18);
    });
  });

  describe('ERC20 Standard Operations', () => {
    it('Should transfer tokens between accounts', async () => {
      const amount = 10n * 10n ** 18n;

      await contract.transfer(recipient.address, amount);

      expect(await contract.balanceOf(recipient.address)).to.equal(amount);
      expect(await contract.balanceOf(owner.address)).to.equal(90n * 10n ** 18n);
    });

    it('Should emit Transfer event', async () => {
      const amount = 10n * 10n ** 18n;

      await expect(contract.transfer(recipient.address, amount))
        .to.emit(contract, 'Transfer')
        .withArgs(owner.address, recipient.address, amount);
    });

    it('Should fail transfer with insufficient balance', async () => {
      const hugeAmount = 1000n * 10n ** 18n;

      await expect(
        contract.transfer(recipient.address, hugeAmount)
      ).to.be.reverted;
    });

    it('Should approve and transferFrom', async () => {
      const amount = 50n * 10n ** 18n;

      // Owner approves recipient to spend
      await contract.approve(recipient.address, amount);
      expect(await contract.allowance(owner.address, recipient.address)).to.equal(amount);

      // Recipient transfers from owner to themselves
      await contract.connect(recipient).transferFrom(owner.address, recipient.address, amount);

      expect(await contract.balanceOf(recipient.address)).to.equal(amount);
    });
  });

  describe('Encrypted Balance Getter (View Only)', () => {
    it('Should return encrypted balance handle for any address', async () => {
      // getBalanceEncrypted should be callable (returns euint64 which is uint256)
      const encBalance = await contract.getBalanceEncrypted(owner.address);
      // Without FHE, this returns 0 (no encrypted balance yet)
      expect(encBalance).to.equal(0n);
    });
  });

  // Note: The following tests require FHE infrastructure and will fail on plain hardhat network
  describe.skip('FHE Operations (requires LuxFHE network)', () => {
    it('Should wrap tokens', async () => {
      // This requires the FHE TaskManager precompile
      await contract.wrap(10n);
    });

    it('Should unwrap tokens', async () => {
      await contract.wrap(10n);
      await contract.unwrap(5n);
    });

    it('Should transfer encrypted tokens', async () => {
      // This requires client-side encryption
    });
  });
});
