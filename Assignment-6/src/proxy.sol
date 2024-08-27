// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 
contract NewsReulDAOProxy is TransparentUpgradeableProxy, IERC20 {
    constructor(
            address _implementation,
            address _admin, 
            bytes memory data
        ) 
        TransparentUpgradeableProxy(_implementation, _admin, _data) 
                payable {
    }
}
