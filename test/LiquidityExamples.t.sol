//SPDX-License-Identifier:MIT

pragma solidity =0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import {LiquidityExamples} from "../src/LiquidityExamples.sol";
import {IWETH9} from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract LiquidityExamplesTest is Test {
    LiquidityExamples liquidityExamples;

    ISwapRouter swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address public constant USDC_WHALE =
        0xb4df85cC20B5604496bE657b27194926BD878cee;
    address public constant DAI_WHALE =
        0x7a504Bddc827318606183934bB92e6888b6F9D8a;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() public {
        vm.createSelectFork(
            "https://eth-mainnet.g.alchemy.com/v2/7Mo08KJOJvy7jAI1GzVx2LuXeLuYqz7E"
        );
        liquidityExamples = new LiquidityExamples();
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(address(this), 1000e6);
        vm.prank(DAI_WHALE);
        IERC20(DAI).transfer(address(this), 1000 ether);
        assertEq(IERC20(DAI).balanceOf(address(this)), 1000 ether);
        assertEq(IERC20(USDC).balanceOf(address(this)), 1000e6);
        IERC20(DAI).approve(address(liquidityExamples), type(uint256).max);
        IERC20(USDC).approve(address(liquidityExamples), type(uint256).max);
    }

    function testMintNewPosition() public {
        (uint256 tokenId, , , ) = liquidityExamples.mintNewPosition(
            1000 ether,
            1000e6
        );
        assert(tokenId > 0);
    }

    function testDecreaseLiquidity() public {
        // Mint new position
        (uint256 tokenId, uint128 liquidity, , ) = liquidityExamples
            .mintNewPosition(1000 ether, 1000e6);
        assert(tokenId > 0);

        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(address(this));
        uint256 usdcBalanceBefore = IERC20(USDC).balanceOf(address(this));

        // reduce liquidity.
        // Note reducing liquidity don't automatically send withdrawan amount to
        // sender. You need to call collect all fees after that .

        liquidityExamples.decreaseLiquidityPosition(tokenId, liquidity / 2);
        liquidityExamples.collectAllFees(tokenId);
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(address(this));
        uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(address(this));

        assert(daiBalanceAfter > daiBalanceBefore);
        assert(usdcBalanceAfter > usdcBalanceBefore);
    }

    function testCollectFees() public {
        // Provide liquidity

        (uint256 tokenId, , , ) = liquidityExamples.mintNewPosition(
            1000 ether,
            1000e6
        );

        // Do a large swap in the same liquidity pool. Prank as DAI_WHALE
        vm.startPrank(DAI_WHALE);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: USDC,
                fee: 100,
                recipient: DAI_WHALE,
                deadline: block.timestamp,
                amountIn: 1_000_000 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        IERC20(DAI).approve(address(swapRouter), type(uint256).max);
        swapRouter.exactInputSingle(params);
        vm.stopPrank();

        // Collect Fees
        (uint256 amount0, uint256 amount1) = liquidityExamples.collectAllFees(
            tokenId
        );

        // Liqudity provider should receive some DAI as fee after DAI_WHALE made a large transaction
        assert(amount0 > 0);
    }
}
