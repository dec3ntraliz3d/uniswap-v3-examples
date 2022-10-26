//SPDX-License-Identifier:MIT

pragma solidity =0.7.6;

import "forge-std/Test.sol";
import {SwapExamples} from "../src/SwapExamples.sol";
import {IWETH9} from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapExamplesTest is Test {
    SwapExamples swapper;
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function setUp() public {
        vm.createSelectFork(
            "https://eth-mainnet.g.alchemy.com/v2/7Mo08KJOJvy7jAI1GzVx2LuXeLuYqz7E"
        );
        swapper = new SwapExamples();
        weth.deposit{value: 10 ether}();
        assertEq(weth.balanceOf(address(this)), 10 ether);
        weth.approve(address(swapper), 10 ether);
    }

    function testSwapExactInputSingle() public {
        swapper.swapExactInputSingle(1 ether);
        console.log(dai.balanceOf(address(this)));
        assert(dai.balanceOf(address(this)) > 0);
    }

    function testSwapExactInputMultihop() public {
        swapper.swapExactInputMultihop(1 ether);
        console.log(dai.balanceOf(address(this)));
        assert(dai.balanceOf(address(this)) > 0);
    }

    function testSwapExactOutputSingle() public {
        swapper.swapExactOutputSingle(100 ether, 0.1 ether);
        assert(dai.balanceOf(address(this)) == 100 ether);
    }

    function testSwapExactOutputMultihop() public {
        swapper.swapExactOutputMultihop(100 ether, 1 ether);
        assert(dai.balanceOf(address(this)) == 100 ether);
    }
}
