// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Initializable.sol";

import "./interfaces/IAccessControl.sol";


// interface IBlast {
//   // Note: the full interface for IBlast can be found below
//   function configureClaimableGas() external;
//   function configureGovernor(address governor) external;
// }
// interface IBlastPoints {
//   function configurePointsOperator(address operator) external;
// }

// // https://docs.blast.io/building/guides/gas-fees
// // added constant: BLAST_GOV
// contract BlastClaimableGas {
//   IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
//   // todo
//   // replace gov address
//   address constant private BLAST_GOV = address(0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F);

//   function initClaimableGas() internal {
//     BLAST.configureClaimableGas();
//     // This sets the contract's governor. This call must come last because after
//     // the governor is set, this contract will lose the ability to configure itself.
//     BLAST.configureGovernor(BLAST_GOV);
//     IBlastPoints(0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800).configurePointsOperator(0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F);
//   }
// }

// contract UseAccessControl is Initializable, BlastClaimableGas {
contract UseAccessControl is Initializable {
    event ApproveAdmin(
        address indexed account,
        address indexed admin
    );

    event RevokeAdmin(
        address indexed account,
        address indexed admin
    );

    modifier onlyOwner() {
        require(_accessControl.isOwner(msg.sender), "onlyOwner");
        _;
    }

    modifier onlyAdmin() {
        require(_accessControl.isAdmin(msg.sender), "onlyAdmin");
        _;
    }

    modifier onlyApprovedAdmin(
        address account_
    )
    {
        address admin = msg.sender;
        require(_accessControl.isAdmin(admin), "onlyAdmin");
        require(_isApprovedAdmin[account_][admin], "onlyApprovedAdmin");
        _;
    }

    IAccessControl internal _accessControl;

    mapping(address => mapping(address => bool)) private _isApprovedAdmin;

    function initUseAccessControl(
        address accessControl_
    )
        public
        initializer
    {
        _accessControl = IAccessControl(accessControl_);
        // initClaimableGas();
    }

    function approveAdmin(
        address admin_
    )
        external
    {
        address account = msg.sender;
        require(_accessControl.isAdmin(admin_), "onlyAdmin");
        require(!_isApprovedAdmin[account][admin_], "onlyNotApprovedAdmin");
        _isApprovedAdmin[account][admin_] = true;
        emit ApproveAdmin(account, admin_);
    }

    function revokeAdmin(
        address admin_
    )
        external
    {
        address account = msg.sender;
        require(_accessControl.isAdmin(admin_), "onlyAdmin");
        require(_isApprovedAdmin[account][admin_], "onlyApprovedAdmin");
        _isApprovedAdmin[account][admin_] = false;
        emit RevokeAdmin(account, admin_);
    }

    function isApprovedAdmin(
        address account_,
        address admin_
    )
        external
        view
        returns(bool)
    {
        return _isApprovedAdmin[account_][admin_];
    }
}
