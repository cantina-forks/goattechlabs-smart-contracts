// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./modules/interfaces/IVester.sol";

contract PrivateVester is Ownable{
    IVester private _vester;
    IERC20 private _token;

    function config(
        IVester vester_,
        IERC20 token_
    )
        external
        onlyOwner
    {
        _vester = vester_;
        _token = token_;
    }

    function _sendTo(
        address invester_,
        uint amount_,
        uint vestingDur_,
        uint vestingPercent_,
        uint cliff_
    )
        internal
    {
        uint vestingA = amount_ * vestingPercent_ / 10000;
        uint directA = amount_ - vestingA;
        _token.transfer(invester_, directA);
        _token.transfer(address(_vester), vestingA);
        _vester.lock(invester_, vestingDur_, cliff_);
    }

    function transferLock(
        address from_,
        address to_,
        uint amount_
    )
        external
        onlyOwner
    {
        _vester.transferLock(from_, to_, amount_);
        _vester.unlock(to_);
    }

    // function forcedUnlock(
    //     address account_,
    //     uint amount_
    // )
    //     external
    //     onlyOwner
    // {
    //     _vester.forcedUnlock(account_, amount_);
    // }

    function withdraw(
        address dest_,
        uint amount_
    )
        external
        onlyOwner
    {
        _token.transfer(dest_, amount_);
    }

    function sendTos(
        address[] memory investers_,
        uint[] memory amounts_,
        uint[] memory vestingDurs_,
        uint[] memory vestingPercents_,
        uint[] memory cliffs_
    )
        external
        onlyOwner
    {
        for(uint i = 0; i < investers_.length; i++) {
            _sendTo(investers_[i], amounts_[i], vestingDurs_[i], vestingPercents_[i], cliffs_[i]);
        }
    }

    function vester()
        external
        view
        returns(address)
    {
        return address(_vester);
    }

    function token()
        external
        view
        returns(address)
    {
        return address(_token);
    }
}
