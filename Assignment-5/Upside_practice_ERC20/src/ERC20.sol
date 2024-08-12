// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ERC20Pausable} from "./ERC20Pausable.sol";

contract ERC20 is ERC20Pausable, EIP712, Nonces  {
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_) EIP712(name_, "1") {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, 100 ether);
    }
    /** Metadata start */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }
    /** Metadata end */

    /** executable Functions start */
    function transfer(address to, uint256 value) public virtual whenNotPaused() returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual whenNotPaused() returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value); // allowance를 소비하여 transferFrom을 함    
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public virtual whenNotPaused() returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value);
        return true;
    }
    /** executable functions end */

    /** internal functions start */
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "Invalid Sender");
        require(to != address(0), "Invalid Receiver");
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal {
        if (from == address(0)) { // mint
            _totalSupply += value;
        } 
        else
        {
            uint256 fromBalance = _balances[from];
            require(fromBalance >= value, "Insufficient Balance");
            unchecked { // require에서 검사했기 때문에, unchecked로 해도 됨
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) { // burn
            unchecked {
                // value가 totalsupply보다 작거나 같기 때문에, 오버플로우 안일어남.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // balance에서 value를 더해도 totalsupply보다 작거나 같기 때문에, 오버플로우 안일어남
                _balances[to] += value;
            }
        }
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "Invalid Receiver");
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "Invalud Sender");
        _update(account, address(0), value);
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= value, "Insufficient Allowance");
        _approve(owner, spender, currentAllowance - value);   
    } 
    // currentAllowance가 type(uint).max일 경우에 spend를 하지 않도록 되어있는데,
    // gas 소모 때문에 그렇게 되어있던 것 같다.

    function _approve(address owner, address spender, uint256 value) internal virtual {
        require(owner != address(0), "Invalid Approver");
        require(spender != address(0), "Invalid Spender");
        _allowances[owner][spender] = value;
    }
    /** internal functions end */

    /** ERC20Permit start */
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "Expired Signature");
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "INVALID_SIGNER");
        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual override(Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    /** override */
    function _toTypedDataHash(bytes32 structHash) public returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }
    /** ERC20Permit end */
}
