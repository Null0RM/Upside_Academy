// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20Pausable {
    bool private _paused;
    address private owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }
    modifier whenPaused() {
        _requirePaused();
        _;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Expect not paused");
    }
    function _requirePaused() internal view virtual {
        require(paused(), "Expect paused");
    }
    function pause() public virtual whenNotPaused onlyOwner() {
        _paused = true;
    }
    function unpause() public virtual whenPaused onlyOwner() {
        _paused = false;
    }
}
