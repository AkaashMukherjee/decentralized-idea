// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol";
import "github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

contract LiquidityLauncher {
    
    mapping(address => LaunchInformation) TokenToLaunchInformation;
    mapping(address => mapping(address => mapping(address => uint256))) LiquidityProvider;

    struct LaunchInformation {
        uint256 bestBefore;
        uint256 amountRequiredForLaunchTokenB;
        uint256 storedForThisAddressTokenB;
        uint256 tokenCommitmentA;
    }

    function Create(address tokenAddressA, uint256 tokenCommitmentA, uint256 bestBefore, uint256 amountRequiredForLaunchTokenB) public {
        if(TokenToLaunchInformation[tokenAddressA].amountRequiredForLaunchTokenB!=0){return;}
        IERC20 tokenContract = IERC20(tokenAddressA);
        tokenContract.transferFrom(msg.sender, address(this), tokenCommitmentA);
        TokenToLaunchInformation[tokenAddressA] = LaunchInformation(bestBefore, amountRequiredForLaunchTokenB, 0, tokenCommitmentA);
    }
    
    function LiquidityCommitment(address tokenAddressA, address tokenAddressB, uint256 tokenCommitmentB) public  {
        if(TokenToLaunchInformation[tokenAddressA].storedForThisAddressTokenB>TokenToLaunchInformation[tokenAddressA].amountRequiredForLaunchTokenB){return;}
        IERC20 tokenContract = IERC20(tokenAddressB);
        tokenContract.transferFrom(msg.sender, address(this), tokenCommitmentB);
        TokenToLaunchInformation[tokenAddressA].storedForThisAddressTokenB += tokenCommitmentB;
        LiquidityProvider[msg.sender][tokenAddressA][tokenAddressB] += tokenCommitmentB;
    }

    function GetBNBBalance() public view returns (uint256){
        return address(this).balance;
    }
    
    function GetAllowance(address tokenOwner, address tokenAddress) public view returns (uint){
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.allowance(tokenOwner, address(this));
        
    }
    
    function GetTokenBalance(address tokenAddress) public view returns (uint){
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.balanceOf(address(this));
        
    }
    
    function ExecuteLaunch(address tokenAddressA, address tokenAddressB) public {
        //if(
          //  TokenToLaunchInformation[tokenAddress].bnbStoredForThisAddress>=TokenToLaunchInformation[tokenAddress].bnbRequiredForLaunch &&
            //TokenToLaunchInformation[tokenAddress].bestBefore>= block.timestamp
        //){
            //ganache-cli --deterministic --allowUnlimitedContractSize --fork https://mainnet.infura.io/v3/f6c763fa9d4638ad434ab29cb87c1b --unlock 0x1aD91ee08f21bE3dE0BA2ba6918E714dA6B45836
            IERC20 tokenContractA = IERC20(tokenAddressA);
            IERC20 tokenContractB = IERC20(tokenAddressB);
            address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            tokenContractA.approve(routerAddress, tokenContractA.balanceOf(address(this)));
            tokenContractB.approve(routerAddress, tokenContractB.balanceOf(address(this)));
            IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(routerAddress);
            pancakeRouter.addLiquidity(
                tokenAddressA,
                tokenAddressB,
                TokenToLaunchInformation[tokenAddressA].tokenCommitmentA,
                TokenToLaunchInformation[tokenAddressA].storedForThisAddressTokenB,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(this),
                block.timestamp + 360
            );
            return;
        //}
    }
    
    function removeETHLiquidityFromToken(address tokenAddressLP, address tokenAddressA, address tokenAddressB) public {
        
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(routerAddress);
        
        
        // approve token
        IERC20(tokenAddressLP).approve(routerAddress, IERC20(tokenAddressLP).balanceOf(address(this)));
        
        // remove liquidity
        pancakeRouter.removeLiquidity(tokenAddressA, tokenAddressB, IERC20(tokenAddressLP).balanceOf(address(this)), 0, 0, address(this), now + 20);
        
}

}