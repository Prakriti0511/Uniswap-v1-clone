// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    // Future code goes here
    address public tokenAddress;
    constructor(address token) ERC20("ETH TOKEN LP Token","lpETHTOKEN"){
        require(token!= address(0), "Token address passed is a null address");
        tokenAddress = token;
    }
    function getReserve() public view returns(uint256){
        return ERC20(tokenAddress).balanceOf(address(this));
    }
    function addLiquidity(uint256 amountOfToken) public payable returns(uint256) {
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);
        
        if(tokenReserveBalance == 0){
            token.transferFrom(msg.sender, address(this), amountOfToken);
            lpTokensToMint = ethReserveBalance;

            _mint(msg.sender, lpTokensToMint);

            return lpTokensToMint;
        }

        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 minTokenAmountRequired = (msg.value * tokenReserveBalance)/ ethReservePriorToFunctionCall;

        require(amountOfToken>= minTokenAmountRequired, "Insufficient amount of tokens provided");
        token.transferFrom(msg.sender, address(this), minTokenAmountRequired);
        
        lpTokensToMint = (totalSupply() * msg.value)/ethReservePriorToFunctionCall;

        _mint(msg.sender, lpTokensToMint);
        return lpTokensToMint;
    }
    function removeLiquidity(uint256 amountOfLPTokens) public returns (uint256, uint256){
        require(amountOfToken>0,"Amount of token to remove must be greater thyan 0");
        uint256 ethReserveBalance = address(this).balance;
        uint256 lpTokenTotalSupply = totalSupply();

        uint256 ethToReturn = (ethReserveBalance*amountOfLPTokens)/lpTokenTotalSupply;
        _burn(msg.sender, amountOfToken);
        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);

        return(ethToReturn, tokenToReturn);
    }
    // getOutputAmountFromSwap calculates the amount of output tokens to be received based on xy = (x + dx)(y - dy)
    function getOutputAmountFromSwap(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns(uint256){
        require(inputReserve > 0 && outputReserve > 0, "Reserve must be greater than 0");
        uint256 inputAmountWithFee = inputAmount*99;
        uint256 numerator = inputAmountWithFee*outputReserve;
        uint256 denominator = (inputReserve*100) + inputAmountWithFee;
        return numerator / denominator;
    }

    function ethToTokenSwap(uint256 minTokensToReceive) public payable{
        uint256 tokenReserveBalance = getReserve();
        uint256 tokensToReceive = getOutputAmountFromSwap(msg.value, address(this).balance - msg.value, tokenReserveBalance);
        require(tokensToReceive>= minTokensToReceive,"Tokens received are less than minimum tokens expected");
        ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
    }
    function tokenToEthSwap(uint256 tokensToSwap, uint256 minEthToReceive) public {
    uint256 tokenReserveBalance = getReserve();
    uint256 ethToReceive = getOutputAmountFromSwap(
        tokensToSwap,
        tokenReserveBalance,
        address(this).balance
    );

    require(ethToReceive >= minEthToReceive, "ETH received is less than minimum ETH expected");
    ERC20(tokenAddress).transferFrom(msg.sender, address(this), tokensToSwap);
    payable(msg.sender).transfer(ethToReceive);
}


}