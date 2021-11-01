    // SPDX-License-Identifier: MIT
    
    pragma solidity ^0.6.0;
    
    import "github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol";
    import "github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
    
    contract LiquidityLauncher {
        
        address tokenAddressA;
        address tokenAddressB;
        constructor(address _tokenAddressA, address _tokenAddressB) public {
            tokenAddressA = _tokenAddressA;
            tokenAddressB = _tokenAddressB;
        }
        
        mapping(address => uint256) LiquidityProvider;
    
        struct LaunchInformation {
            uint256 tokenCommitmentA;
            uint256 bestAfter;
            uint256 amountRequiredForLaunchTokenB;
            uint256 storedForThisAddressTokenB;
        }
        
        LaunchInformation launchInformation;
    
        function Create(uint256 tokenCommitmentA, uint256 bestAfter, uint256 amountRequiredForLaunchTokenB) public {
            require(launchInformation.amountRequiredForLaunchTokenB==0, "contract already created for this token");
            IERC20 tokenContract = IERC20(tokenAddressA);
            tokenContract.transferFrom(msg.sender, address(this), tokenCommitmentA);
            launchInformation = LaunchInformation(tokenCommitmentA, block.timestamp + bestAfter * 1 seconds, amountRequiredForLaunchTokenB, 0);
        }
        
        function LiquidityCommitment(uint256 tokenCommitmentB) public  {
            require(RemainingInvestment()>=tokenCommitmentB, "token commitment exceeds remaining investment");
            IERC20 tokenContract = IERC20(tokenAddressB);
            tokenContract.transferFrom(msg.sender, address(this), tokenCommitmentB);
            launchInformation.storedForThisAddressTokenB += tokenCommitmentB;
            LiquidityProvider[msg.sender] += tokenCommitmentB;
        }
        
        function RemainingInvestment () public view returns (uint256){
            return launchInformation.amountRequiredForLaunchTokenB - GetTokenBalance(tokenAddressB);
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
        
        function GetTime() public view returns (uint256){
            return block.timestamp;
        }
        
        function GetAmountRequiredForLaunch() public view returns (uint256){
            return launchInformation.amountRequiredForLaunchTokenB;
        }
        
        function ExecuteLaunch() public {
            require(launchInformation.amountRequiredForLaunchTokenB<= GetTokenBalance(tokenAddressB), "balance less than required for launch");
            require(launchInformation.bestAfter<= block.timestamp, "before launch date");
                IERC20 tokenContractA = IERC20(tokenAddressA);
                IERC20 tokenContractB = IERC20(tokenAddressB);
                address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
                tokenContractA.approve(routerAddress, tokenContractA.balanceOf(address(this)));
                tokenContractB.approve(routerAddress, tokenContractB.balanceOf(address(this)));
                IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(routerAddress);
                pancakeRouter.addLiquidity(
                    tokenAddressA,
                    tokenAddressB,
                    launchInformation.tokenCommitmentA,
                    launchInformation.storedForThisAddressTokenB,
                    0, // slippage is unavoidable
                    0, // slippage is unavoidable
                    address(this),
                    block.timestamp + 360
                );
                return;
        }
        
        function removeLiquidity(address tokenAddressLP) public {
            
            address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(routerAddress);
            
            // approve token
            IERC20(tokenAddressLP).approve(routerAddress, IERC20(tokenAddressLP).balanceOf(address(this)));
            
            // remove liquidity
            pancakeRouter.removeLiquidity(tokenAddressA, tokenAddressB, IERC20(tokenAddressLP).balanceOf(address(this)), 0, 0, address(this), now + 20);
            
        }
    
    }