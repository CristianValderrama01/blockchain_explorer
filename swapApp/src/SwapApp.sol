// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IV2Router02.sol';
import './interfaces/IFactory.sol';

contract SwapApp {

    using SafeERC20 for IERC20;

    address public v2Router02Address;
    address public uniswapFactoryAddress;
    address public usdtAddres;
    address public daiAddress;

    event SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(address tokenA, address tokenB, uint256 lpTokenAmmount);

    constructor(address v2Router02Address_, address uniswapFactoryAddress_, address usdtAddess_, address daiAddress_) {
        v2Router02Address = v2Router02Address_;
        usdtAddres = usdtAddess_;
        daiAddress = daiAddress_;
        uniswapFactoryAddress = uniswapFactoryAddress_;
    }

    function swapTokens(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        uint256 deadline_) public returns (uint256) {

            IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);
            IERC20(path_[0]).approve(v2Router02Address, amountIn_);
            uint[] memory amountsOut = IV2Router02(v2Router02Address).swapExactTokensForTokens(amountIn_, amountOutMin_, path_, msg.sender, deadline_);

        emit SwapTokens(path_[0], path_[path_.length -1], amountIn_, amountsOut[amountsOut.length -1]);

        return amountsOut[amountsOut.length -1];
    }

    function swapTokensForaddLiquidity(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        address to,
        uint256 deadline_) private returns (uint256) {

            IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);
            IERC20(path_[0]).approve(v2Router02Address, amountIn_);
            uint[] memory amountsOut = IV2Router02(v2Router02Address).swapExactTokensForTokens(amountIn_, amountOutMin_, path_, to, deadline_);

        emit SwapTokens(path_[0], path_[path_.length -1], amountIn_, amountsOut[amountsOut.length -1]);

        return amountsOut[amountsOut.length -1];
    }

    function addLiquidity(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        uint256 deadline_) external {

            uint256 halfAmountIn = amountIn_ / 2;

            IERC20(usdtAddres).safeTransferFrom(msg.sender, address(this), halfAmountIn);
            uint256 amountDaiSwap = swapTokensForaddLiquidity(halfAmountIn, amountOutMin_, path_, address(this), deadline_);
            
            IERC20(usdtAddres).approve(v2Router02Address, halfAmountIn);
            IERC20(daiAddress).approve(v2Router02Address, amountDaiSwap);

            (,,uint256 lpTokenAmmount) = IV2Router02(v2Router02Address).addLiquidity(
                usdtAddres, 
                daiAddress, 
                halfAmountIn, 
                amountDaiSwap, 
                amountAMin_, 
                amountBMin_, 
                msg.sender, 
                deadline_);

            emit AddLiquidity(usdtAddres, daiAddress, lpTokenAmmount);
    }


    function removeLiquidity(
        uint256 liquidityAmount_,
        uint256 amountAMin_,
        uint256 amountBMin_,
        uint256 deadline_
    ) external {

        address lpTokensAddress = IFactory(uniswapFactoryAddress).getPair(usdtAddres, daiAddress);
        IERC20(lpTokensAddress).approve(v2Router02Address, liquidityAmount_);
        IV2Router02(v2Router02Address).removeLiquidity(usdtAddres, daiAddress, liquidityAmount_, amountAMin_, amountBMin_, msg.sender, deadline_);
    }
}