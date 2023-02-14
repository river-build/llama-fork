// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

interface IVertexAccount {
    /// @notice Function for Vertex to transfer native tokens to other parties
    /// @param recipient Transfer's recipient
    /// @param amount Amount to transfer
    function transfer(address payable recipient, uint256 amount) external;

    /// @notice Function for Vertex to transfer ERC20 tokens to other parties
    /// @param token The address of the token to transfer
    /// @param recipient Transfer's recipient
    /// @param amount Amount to transfer
    function transferERC20(IERC20 token, address recipient, uint256 amount) external;

    /// @notice Function for Vertex to give ERC20 allowance to other parties
    /// @param token The address of the token to give allowance from
    /// @param recipient Allowance's recipient
    /// @param amount Allowance to approve
    function approveERC20(IERC20 token, address recipient, uint256 amount) external;
}