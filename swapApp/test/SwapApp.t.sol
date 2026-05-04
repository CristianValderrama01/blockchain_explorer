// SPDX-License-Identifier: GPL-3.0
// forge test -vvvv --fork-url https://arb1.arbitrum.io/rpc --match-test <test>

pragma solidity 0.8.24;

import 'forge-std/Test.sol';
import '../src/SwapApp.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import "forge-std/console.sol";

contract SwapAppTest is Test {

    SwapApp app;
    address v2Router02Address = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address uniswapV2FactoryAddress = 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9;
    address user = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    function setUp() public {
        app = new SwapApp(v2Router02Address, uniswapV2FactoryAddress, USDT, DAI);
    }

    function testCorrectlyDeploy() public view {
        assert(app.v2Router02Address() == v2Router02Address);
        console.log("USDT user:", IERC20(USDT).balanceOf(user));
    }

    function testSwapTokensCorrectly() public {

        vm.startPrank(user);

        uint256 amountIn = 5 * 1e6;
        uint256 amountOutMin = 4 * 1e18;
        uint256 deadline = block.timestamp + 10000000;

        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;

        uint256 beforeBalanceUsdt = IERC20(USDT).balanceOf(user);
        uint256 beforeBalanceDai = IERC20(DAI).balanceOf(user);

        IERC20(USDT).approve(address(app), amountIn);
        app.swapTokens(amountIn, amountOutMin, path, deadline);

        uint256 afterBalanceUsdt = IERC20(USDT).balanceOf(user);
        uint256 afterBalanceDai = IERC20(DAI).balanceOf(user);


        assert(afterBalanceUsdt == beforeBalanceUsdt - amountIn);
        assert(afterBalanceDai > beforeBalanceDai );

        vm.stopPrank();
    }

    function testAddLiquidityCorrectly() public {
        vm.startPrank(user);

        uint256 amountIn_ = 5 * 1e6;
        uint256 amountOutMin_ = 2 * 1e6;
        uint256 amountAMin_ = 2 * 1e6;
        uint256 amountBMin_ = 2 * 1e6;
        uint256 deadline_ = block.timestamp + 10000000;

        address[] memory path_ = new address[](2);
        path_[0] = USDT;
        path_[1] = DAI;

        IERC20(USDT).approve(address(app), amountIn_);
        IERC20(DAI).approve(address(app), amountIn_);
        app.addLiquidity(amountIn_, amountOutMin_, path_, amountAMin_, amountBMin_, deadline_);

        vm.stopPrank();
    }

}