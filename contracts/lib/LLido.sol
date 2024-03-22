// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "../modules/interfaces/IWETH.sol";

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function burn(uint256 tokenId) external payable;

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint amount0, uint amount1);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        // uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint amountOut);
}

interface IUniswapV3Factory {
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

// interface IWETH is IERC20 {
//     function deposit() external payable;

//     function withdraw(uint amount) external;
// }

library LLido {
    ISwapRouter private constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IWETH internal constant weth =
        IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    // TESTNET
    // REPLACE THIS BY TEST WSTETH
    IERC20 internal constant wsteth =
        IERC20(0x0D47dF42B5d503EcC6A366499B2B97c7D5Ad42eE);

    uint24 private constant POOL_FEE = 100;

    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    INonfungiblePositionManager private constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function createPairForTestnet(
        address wstethAddr_
    )
        internal
    {
        IUniswapV3Factory factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        factory.createPool(address(weth), wstethAddr_, POOL_FEE);
    }

    function add(
        uint tokenId_
    )
        internal
        returns(uint128 liquidity)
    {
        uint amount = weth.balanceOf(address(this));
        uint wethA = amount / 2;
        buyWsteth(amount - wethA);
        uint wstethA = wsteth.balanceOf(address(this));
        (liquidity, , ) = increaseLiquidityCurrentRange(tokenId_, wethA, wstethA);
    }

    function remove(
        uint tokenId_,
        uint128 decLiqA_
    )
        internal
    {
        decreaseLiquidityCurrentRange(tokenId_, decLiqA_);
        collectAllFees(tokenId_);
        uint wstethA = wsteth.balanceOf(address(this));
        sellWsteth(wstethA);
    }

    function mint()
        internal
        returns(uint tokenId, uint128 liquidity)
    {
        uint amount = weth.balanceOf(address(this));
        uint wethA = amount / 2;
        buyWsteth(amount - wethA);
        uint wstethA = wsteth.balanceOf(address(this));
        (tokenId, liquidity, , ) = mintNewPosition(wethA, wstethA);
    }

    function buyWsteth(
        uint wethA_
    )
        public
    {
        if (wethA_ == 0) {
            return;
        }
        weth.approve(address(router), wethA_);
        swapExactInputSingleHop(
            address(weth),
            address(wsteth),
            wethA_
        );
    }

    function allToWsteth(
        uint minWstethBal_
    )
        public
    {
        ethToWeth();
        buyWsteth(weth.balanceOf(address(this)));
        require(wsteth.balanceOf(address(this)) > minWstethBal_, "slipped too high");
    }

    function allToEth(
        uint minEthBal_
    )
        public
    {
        sellWsteth(wsteth.balanceOf(address(this)));
        wethToEth();
        require(address(this).balance > minEthBal_, "slipped too high");
    }

    function sellWsteth(
        uint wstethA_
    )
        public
    {
        if (wstethA_ == 0) {
            return;
        }
        wsteth.approve(address(router), wstethA_);
        swapExactInputSingleHop(
            address(wsteth),
            address(weth),
            wstethA_
        );
    }

    function wethToEth()
        public
    {
        uint amount = weth.balanceOf(address(this));
        if (amount > 0) {
            weth.withdraw(amount);
        }
    }

    function ethToWeth()
        public
    {
        uint amount = address(this).balance;
        if (amount > 0) {
            weth.deposit{value: amount}();
        }
    }

    function mintNewPosition(
        uint wethA_,
        uint wstethA_
    )
        internal
        returns
        (uint tokenId, uint128 liquidity, uint amount0, uint amount1)
    {
        weth.approve(address(nonfungiblePositionManager), wethA_);
        wsteth.approve(address(nonfungiblePositionManager), wstethA_);

        address token0 = address(weth) < address(wsteth) ? address(weth) : address(wsteth);
        address token1 = token0 == address(weth) ? address(wsteth) : address(weth);
        uint amount0ToAdd = token0 == address(weth) ? wethA_ : wstethA_;
        uint amount1ToAdd = token0 == address(weth) ? wstethA_ : wethA_;

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: POOL_FEE,
                tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING,
                tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );
    }

    function increaseLiquidityCurrentRange(
        uint tokenId_,
        uint wethA_,
        uint wstethA_
    ) internal returns (uint128 liquidity, uint amount0, uint amount1) {

        weth.approve(address(nonfungiblePositionManager), wethA_);
        wsteth.approve(address(nonfungiblePositionManager), wstethA_);

        address token0 = address(weth) < address(wsteth) ? address(weth) : address(wsteth);
        // address token1 = token0 == address(weth) ? address(wsteth) : address(weth);
        uint amount0ToAdd = token0 == address(weth) ? wethA_ : wstethA_;
        uint amount1ToAdd = token0 == address(weth) ? wstethA_ : wethA_;

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId_,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(
            params
        );
    }

    function collectAllFees(
        uint tokenId_
    ) internal returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId_,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function getLiquidity(
        uint tokenId_
    )
        internal
        view
        returns (uint128)
    {
        (, , , , , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId_);
        return liquidity;
    }

    function decreaseLiquidityCurrentRange(
        uint tokenId_,
        uint128 decLiqA_
    )
        internal
        returns (uint amount0, uint amount1)
    {
        //todo
        // check liq param
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId_,
                liquidity: decLiqA_,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
    }

    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint amountIn
    )
        internal
        returns (uint amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: POOL_FEE,
                recipient: address(this),
                // deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }
}
