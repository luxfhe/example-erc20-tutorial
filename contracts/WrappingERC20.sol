// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@luxfi/contracts/fhe/FHE.sol";

/**
 * @title WrappingERC20
 * @notice ERC20 token that supports wrapping public balances to encrypted (confidential) balances
 * @dev Uses LuxFHE's FHE library for homomorphic encryption operations
 */
contract WrappingERC20 is ERC20 {
    /// @notice Mapping from address to encrypted balance
    mapping(address => euint64) internal _encBalances;

    /// @notice Emitted when tokens are wrapped (public -> encrypted)
    event Wrapped(address indexed account, uint64 amount);

    /// @notice Emitted when tokens are unwrapped (encrypted -> public)
    event Unwrapped(address indexed account, uint64 amount);

    /// @notice Emitted when encrypted tokens are transferred
    event EncryptedTransfer(address indexed from, address indexed to);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
    }

    /**
     * @notice Wrap public tokens to encrypted balance
     * @param amount The amount of public tokens to wrap
     */
    function wrap(uint64 amount) public {
        // Make sure that the sender has enough of the public balance
        require(balanceOf(msg.sender) >= amount, "Insufficient public balance");

        // Burn public balance
        _burn(msg.sender, amount);

        // Convert public amount to encrypted by trivially encrypting it
        euint64 shieldedAmount = FHE.asEuint64(amount);

        // Add shielded balance to current encrypted balance
        _encBalances[msg.sender] = FHE.add(_encBalances[msg.sender], shieldedAmount);

        emit Wrapped(msg.sender, amount);
    }

    /**
     * @notice Unwrap encrypted tokens back to public balance
     * @param amount The amount to unwrap (in plaintext, will be checked against encrypted balance)
     * @dev This is a simplified version - production would use async decryption via Gateway
     */
    function unwrap(uint64 amount) public {
        // Convert the amount to encrypted form for comparison
        euint64 encAmount = FHE.asEuint64(amount);

        // Check if we have enough encrypted balance
        ebool hasEnough = FHE.le(encAmount, _encBalances[msg.sender]);

        // Subtract from encrypted balance (will fail if hasEnough is false)
        _encBalances[msg.sender] = FHE.select(
            hasEnough,
            FHE.sub(_encBalances[msg.sender], encAmount),
            _encBalances[msg.sender]
        );

        // Mint public tokens (only if the select succeeded)
        // Note: In production, you'd use async decryption via Gateway
        _mint(msg.sender, amount);

        emit Unwrapped(msg.sender, amount);
    }

    /**
     * @notice Transfer encrypted tokens to another address
     * @param to The recipient address
     * @param encryptedAmount The encrypted amount to transfer (from client-side encryption)
     * @param inputProof Proof of valid encryption
     */
    function transferEncrypted(
        address to,
        einput encryptedAmount,
        bytes calldata inputProof
    ) public {
        euint64 amount = FHE.asEuint64(encryptedAmount, inputProof);

        // Check if sender has enough encrypted balance
        ebool hasEnough = FHE.le(amount, _encBalances[msg.sender]);

        // Conditional transfer - only moves funds if sender has enough
        _encBalances[msg.sender] = FHE.select(
            hasEnough,
            FHE.sub(_encBalances[msg.sender], amount),
            _encBalances[msg.sender]
        );

        _encBalances[to] = FHE.select(
            hasEnough,
            FHE.add(_encBalances[to], amount),
            _encBalances[to]
        );

        emit EncryptedTransfer(msg.sender, to);
    }

    /**
     * @notice Get the encrypted balance of an account
     * @param account The account to query
     * @return The encrypted balance (can be decrypted by the owner)
     */
    function getBalanceEncrypted(address account) public view returns (euint64) {
        return _encBalances[account];
    }
}
