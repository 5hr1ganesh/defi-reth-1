// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRETH} from "../interfaces/rocket-pool/IRETH.sol";
import {IRocketDepositPool} from
    "../interfaces/rocket-pool/IRocketDepositPool.sol";
import {IRocketDAOProtocolSettingsDeposit} from
    "../interfaces/rocket-pool/IRocketDAOProtocolSettingsDeposit.sol";
import {IRocketStorage} from "../interfaces/rocket-pool/IRocketStorage.sol";
import {
    RETH,
    ROCKET_STORAGE,
    ROCKET_DEPOSIT_POOL,
    ROCKET_DAO_PROTOCOL_SETTINGS_DEPOSIT
} from "../Constants.sol";

/// @title SwapRocketPool
/// @notice This contract facilitates swapping between ETH and rETH using RocketPool.
/// @dev The contract interacts with RocketPool's deposit pool, rETH token, and protocol settings.
contract SwapRocketPool {
    IRETH constant reth = IRETH(RETH);
    IRocketStorage constant rStorage = IRocketStorage(ROCKET_STORAGE);
    IRocketDepositPool constant depositPool =
        IRocketDepositPool(ROCKET_DEPOSIT_POOL);
    IRocketDAOProtocolSettingsDeposit constant protocolSettings =
        IRocketDAOProtocolSettingsDeposit(ROCKET_DAO_PROTOCOL_SETTINGS_DEPOSIT);

    uint256 constant CALC_BASE = 1e18;

    /// @notice Allows the contract to receive ETH.
    receive() external payable {}

    /// @notice Calculates the amount of rETH received and fee charged for a given ETH amount.
    /// @param ethAmount The amount of ETH to be converted to rETH.
    /// @return rEthAmount The calculated amount of rETH to be received.
    /// @return fee The deposit fee deducted from the ETH amount.
    function calcEthToReth(uint256 ethAmount)
        external
        view
        returns (uint256 rEthAmount, uint256 fee)
    {
        uint256 depositFee = protocolSettings.getDepositFee();
        fee = ethAmount * depositFee / CALC_BASE;
        ethAmount -= fee;
        rEthAmount = reth.getRethValue(ethAmount);
    }

    /// @notice Calculates the amount of ETH for a given rETH amount.
    /// @param rEthAmount The amount of rETH to be converted to ETH.
    /// @return ethAmount The calculated amount of ETH to be received.
    function calcRethToEth(uint256 rEthAmount)
        external
        view
        returns (uint256 ethAmount)
    {
        ethAmount = reth.getEthValue(rEthAmount);
    }

    /// @notice Retrieves the deposit availability status and maximum deposit amount.
    /// @return depositEnabled Whether deposits are currently enabled.
    /// @return maxDepositAmount The maximum allowed deposit amount in ETH.
    function getAvailability()
        external
        view
        returns (bool depositEnabled, uint256 maxDepositAmount)
    {
        return (
            protocolSettings.getDepositEnabled(),
            depositPool.getMaximumDepositAmount()
        );
    }

    /// @notice Retrieves the deposit delay for rETH deposits.
    /// @return depositDelay The delay in blocks before deposits are processed.
    function getDepositDelay() external view returns (uint256 depositDelay) {
        return rStorage.getUint(
            keccak256(
                abi.encodePacked(
                    keccak256("dao.protocol.setting.network"),
                    "network.reth.deposit.delay"
                )
            )
        );
    }

    /// @notice Retrieves the block number of the last deposit made by a user.
    /// @param user The address of the user.
    /// @return lastDepositBlock The block number of the user's last deposit.
    function getLastDepositBlock(address user)
        external
        view
        returns (uint256 lastDepositBlock)
    {
        return rStorage.getUint(
            keccak256(abi.encodePacked("user.deposit.block", user))
        );
    }

    /// @notice Swaps ETH to rETH by depositing ETH into the RocketPool deposit pool.
    /// @dev The caller must send ETH with this transaction.
    function swapEthToReth() external payable {
        depositPool.deposit{value: msg.value}();
    }

    /// @notice Swaps rETH to ETH by burning rETH.
    /// @param rEthAmount The amount of rETH to be burned.
    /// @dev The caller must approve the contract to transfer the specified rETH amount.
    function swapRethToEth(uint256 rEthAmount) external {
        reth.transferFrom(msg.sender, address(this), rEthAmount);
        reth.burn(rEthAmount);
    }
}
