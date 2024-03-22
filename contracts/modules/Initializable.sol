// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

contract Initializable {
  bool private _isNotInitializable;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(!_isNotInitializable, "isNotInitializable");
    _;
    _isNotInitializable = true;
  }
}
