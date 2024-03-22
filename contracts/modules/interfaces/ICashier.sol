// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface ICashier {
    function clean()
        external;

    function cleanTo()
        external
        view
        returns(address);

    function currentBalance()
        external
        view
        returns(uint);

    function lastestBalance()
        external
        view
        returns(uint); 
}