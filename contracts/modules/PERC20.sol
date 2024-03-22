// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./UseAccessControl.sol";

contract ATHBalance {
    event UpdateAthBalance(
        address indexed account_,
        uint athBalance
    );

    uint private _athBalance;

    function isContract(address _addr) private view returns (bool){
    uint32 size;
    assembly {
        size := extcodesize(_addr)
    }
    return (size > 0);
    }

    function _updateAthBalance(
        address account_,
        uint balance_
    )
        internal
    {
        if (balance_ > _athBalance && !isContract(account_)) {
            _athBalance = balance_;
            emit UpdateAthBalance(account_, balance_);
        }
    }

    function athBalance()
        external
        view
        returns(uint)
    {
        return _athBalance;
    }
}

contract PERC20 is ERC20, UseAccessControl, ATHBalance {
    event SetInPrivateMode(
        bool inPrivateMode
    );

    bool private _inPrivateMode;
    string private _name;
    string private _symbol;

    bool private _needAthRecord;

    function initPERC20(
        address accessControl_,
        bool inPrivateMode_,
        string memory name_,
        string memory symbol_
    )
        public
        virtual
        initializer
    {
        initUseAccessControl(accessControl_);
        _setInPrivateMode(inPrivateMode_);
        _name = name_;
        _symbol = symbol_;
    }

    function needAthRecord()
        external
        view
        returns(bool)
    {
        return _needAthRecord;
    }

    function activeAthRecord()
        external
        onlyAdmin
    {
        _needAthRecord = true;
    }

    function deactiveAthRecord()
        external
        onlyAdmin
    {
        _needAthRecord = false;
    }

    constructor()
        ERC20("ignored", "ignored")
    {
    }

    function _afterTokenTransfer(
        address,
        address to_,
        uint256
    )
        internal
        virtual
        override
    {
        if (_needAthRecord) {
            _updateAthBalance(to_, balanceOf(to_));
        }
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _setInPrivateMode(
        bool inPrivateMode_
    )
        internal
    {
        _inPrivateMode = inPrivateMode_;
        emit SetInPrivateMode(inPrivateMode_);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(!_inPrivateMode, "_inPrivateMode");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(!_inPrivateMode, "_inPrivateMode");
        return super.transferFrom(from, to , amount);
    }

    function setInPrivateMode(
        bool inPrivateMode_
    )
        external
        onlyOwner
    {
        _setInPrivateMode(inPrivateMode_);
    }

    function mint(
        address account_,
        uint amount_
    )
        external
        onlyAdmin
    {
        _mint(account_, amount_);
    }

    function burn(
        address account_,
        uint amount_
    )
        external
        virtual
        onlyAdmin
    {
        _burn(account_, amount_);
    }
}
