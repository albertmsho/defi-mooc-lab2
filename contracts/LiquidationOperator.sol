//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "hardhat/console.sol";

// ----------------------INTERFACE------------------------------

// Aave
// https://docs.aave.com/developers/the-core-protocol/lendingpool/ilendingpool

interface ILendingPool {
    /**
     * Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of theliquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

// UniswapV2

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/Pair-ERC-20
interface IERC20 {
    // Returns the account balance of another account with address _owner.
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Allows _spender to withdraw from your account multiple times, up to the _value amount.
     * If this function is called again it overwrites the current allowance with _value.
     * Lets msg.sender set their allowance for a spender.
     **/
    function approve(address spender, uint256 value) external; // return type is deleted to be compatible with USDT
    /**
     * Transfers _value amount of debtAsset_USDTs to address _to, and MUST fire the Transfer event.
     * The function SHOULD throw if the message caller’s account balance does not have enough debtAsset_USDTs to spend.
     * Lets msg.sender send pool debtAsset_USDTs to an address.
     **/
    function transfer(address to, uint256 value) external returns (bool);
    
    // Added by Albert
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH is IERC20 {
    // Convert the wrapped WETH back to Ether.
    function withdraw(uint256) external;
}

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Callee.sol
// The flash loan liquidator we plan to implement this time should be a UniswapV2 Callee
interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/factory
interface IUniswapV2Factory {
    // Returns the address of the pair for debtAsset_USDTA and debtAsset_USDTB, if it has been created, else address(0).
    function getPair(address debtAsset_USDTA, address debtAsset_USDTB)
        external
        view
        returns (address pair);
}

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/pair
interface IUniswapV2Pair {
    /**
     * Swaps debtAsset_USDTs. For regular swaps, data.length must be 0.
     * Also see [Flash Swaps](https://docs.uniswap.org/protocol/V2/concepts/core-concepts/flash-swaps).
     **/
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    /**
     * Returns the reserves of WETH_address and debtAsset_USDT used to price trades and distribute liquidity.
     * See Pricing[https://docs.uniswap.org/protocol/V2/concepts/advanced-topics/pricing].
     * Also returns the block.timestamp (mod 2**32) of the last block during which an interaction occured for the pair.
     **/
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// Router

// Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address debtAsset_USDTA,
        address debtAsset_USDTB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address debtAsset_USDT,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address debtAsset_USDTA,
        address debtAsset_USDTB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address debtAsset_USDT,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address debtAsset_USDTA,
        address debtAsset_USDTB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address debtAsset_USDT,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
/******************************/
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address debtAsset_USDT,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address debtAsset_USDT,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
/******************************/

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
// ----------------------IMPLEMENTATION------------------------------

contract LiquidationOperator is IUniswapV2Callee {
    uint8 public constant health_factor_decimals = 18;

    // TODO: define constants used in the contract including ERC-20 debtAsset_USDTs, Uniswap Pairs, Aave lending pools, etc. */
    //    *** Your code here ***
    
     //* @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     //* @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     // * @param user The address of the borrower getting liquidated
       
    address constant AavelendingPoolAddressProvider = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9; // Aave Pool address

    // For correct checksum, click on Etherscan for the address. Once you could find the address "copy" icon, that shall give you the address with correct checksum    
    address constant original_sender = 0xa61e59faC455EED933405ecDde9928982B478CE7; // From:  from Etherscan @ https://etherscan.io/tx/0xac7df37a43fab1b130318bbb761861b8357650db2e2c6493b73d6da3d9581077
    address constant user = 0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F; //User to liquidate - Given address
    address constant collateralAddress_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; // WBTC address @ https://etherscan.io/address/0x2260fac5e5542a773aa44fbcfedf7c193bc2c599
    address constant debtAsset_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT address - top right @ https://etherscan.io/debtAsset_USDT/0xdac17f958d2ee523a2206206994597c13d831ec7?a=0x3ed3b47dd13ec9a98b44e6204a523e766b225811
    address constant WETH_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH address - top right @https://etherscan.io/debtAsset_USDT/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2?a=0xb7990f251451a89728eb2aa7b0a529f51d127478
    
    address constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // so factory address is needed to access the uniswap interfaces here, and then you use this address of the pair to get the rest of the info and to perform the swap
    
    address UNISWAP_ADDRESS_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // @ https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02
    IUniswapV2Router02 private uniswapRouter;

    IWETH internal IWETHToken;

    address pairWBTCWETHAddress; // for XBTC and USDT swap pair address
    address pairWETHUSDTAddress; // for WETH and USDT swap pair address

    // Transaction Action: Liquidator Repay 2,916,378.221684 USDT To Aave Protocol V2
    uint256 debtToCover = 2916378221684; // in USDT Hardcode from https://etherscan.io/tx/0xac7df37a43fab1b130318bbb761861b8357650db2e2c6493b73d6da3d9581077
    
    uint256 totalCollateralETH;
    uint256 totalDebtETH;
    uint256 availableBorrowsETH;
    uint256 currentLiquidationThreshold;
    uint256 ltv;
    uint256 healthFactor;
    bool receiveAToken = false;

    // some helper function, it is totally fine if you can finish the lab without using these function
    // https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // safe mul is not necessary since https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // some helper function, it is totally fine if you can finish the lab without using these function
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // safe mul is not necessary since https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    constructor() {
    // constructor(address _factory) {
        // TODO: (optional) initialize your contract
        // Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleFlashSwap.sol
        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
        // create uniswap factory
        // factory = _factory;
        // END TODO
    }

    // TODO: add a `receive` function so that you can withdraw your WETH
    //   *** Your code here ***
    // Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleFlashSwap.sol
    receive() external payable {}
        
    // END TODO

    // required by the testing script, entry for your liquidation call
    function operate() external {
        // TODO: implement your liquidation logic


        console.log("address(this) :",address(this));
        console.log("***********************************************");
        // You are expected to liquidate 0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F on Aave V2 which was liquidated at block 12489620. 
        // Check out the original liquidation transaction.

        // 0. security checks and initializing variables
        //    *** Your code here ***
          // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
        // ***************************************************************************************
        // get liquidity pair address for debtAsset_USDTs on uniswap     
        // pairWBTCUSDTAddress = IUniswapV2Factory(factory).getPair(collateralAddress_WBTC, debtAsset_USDT); // get uniswap address for WBTC and USDT
        // console.log("Uniswap pairWBTCUSDTAddress :", pairWBTCUSDTAddress);

        pairWETHUSDTAddress = IUniswapV2Factory(factory).getPair(WETH_address, debtAsset_USDT); // get uniswap address for WBTC and USDT
        console.log("Uniswap pairWBTCUSDTAddress :", pairWETHUSDTAddress);
        // END TODO

        console.log("***********************************************");
        console.log(".");
        console.log(".");
        console.log(".");
        console.log("***********************************************");

        // 1. get the target user account data & make sure it is liquidatable
        //    *** Your code here ***
        (totalCollateralETH ,totalDebtETH,availableBorrowsETH,currentLiquidationThreshold,ltv,healthFactor) = ILendingPool(AavelendingPoolAddressProvider).getUserAccountData(user);
        
        console.log("target user account health check under ILending Pool:");
        
        console.log("***********************************************");
        console.log("user :", user); 
        console.log("totalCollateralETH in Wei :", totalCollateralETH); // in Wei
        console.log("totalDebtETH in Wei :" , totalDebtETH); // in Wei
        console.log("availableBorrowsETH in Wei :" , availableBorrowsETH); // in Wei
        console.log("ltv :" , ltv/100); 
        console.log("healthFactor in 10**18:" , healthFactor); // in X/10^18
        console.log("***********************************************");
        require(healthFactor / (10**(health_factor_decimals)) < 1); // only liquidate when healthFactor <=1, decimals is 18 as given

        // 2. call flash swap to liquidate the target user
        // based on https://etherscan.io/tx/0xac7df37a43fab1b130318bbb761861b8357650db2e2c6493b73d6da3d9581077
        // we know that the target user borrowed USDT with WBTC as collateral
        // we should borrow USDT, liquidate the target user and get the WBTC, then swap WBTC to USDT to repay uniswap
        // (please feel free to develop other workflows as long as they liquidate the target user successfully)
        //    *** Your code here ***
        
        // make sure the pair exists in uniswap 
        // require(pairWBTCUSDTAddress != address(0), 'Could not find pool on uniswap'); 
        require(pairWETHUSDTAddress != address(0), 'Could not find pool on uniswap'); 

        /*
        Ref: https://github.com/KaihuaQin/defi-mooc-lab2
        Importantly, Uniswap would attempt to call into the receiver to invoke the function uniswapV2Call after sending the flash loan assets. 
        This means that you need a smart contract to accept a flash loan. The smart contract should have an uniswapV2Call function and 
        you can program how you use the flash loan assets in this function.
        */

        // create flashloan 
        // create pointer to the liquidity pair address 
        // to create a flashloan call the swap function on the pair contract 
        // one amount will be 0 and the non 0 amount is for the debtAsset_USDT you want to borrow 
        // address is where you want to receive debtAsset_USDT that you are borrowing
        // bytes can not be empty.  Need to inculde some text to initiate the flash loan 
        // if bytes is empty it will initiate a traditional swap 
        
        console.log("debtToCover :", debtToCover);

        console.log("***********************************************");
        console.log("Flash loan and liquidation - start!");
        console.log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
        
        IUniswapV2Pair(pairWETHUSDTAddress).swap(0, debtToCover, address(this), bytes('flashloan')); //Hardcoding debtToCover amount here
        
        console.log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
        console.log("Flash loan and liquidation - end!");
        console.log("***********************************************");
        // ***************************************************************************************

        console.log(".");
        console.log(".");
        console.log(".");

        console.log("***********************************************");
        console.log("Withdraw ETH from WETH - start!");
        console.log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");

        // 3. Convert the profit into ETH and send back to sender
        //    *** Your code here ***
        
        uint256 WETH_balance = IERC20(WETH_address).balanceOf(address(this));

        // Withdraw WETH to ETH
        IWETHToken = IWETH(WETH_address);
        IWETHToken.withdraw(WETH_balance);

        // say back ETH from the contract to the msg.sender using ETH method, i.e. not IERC20
        payable(msg.sender).transfer(WETH_balance);

        // In the exercise, you are required to convert every earned debtAsset_USDT to ETH through e.g., exchanges. This is for easing the grading.        

        console.log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
        console.log("Withdraw ETH from WETH! - end!");
        console.log("***********************************************");
        console.log(".");
        console.log(".");
        console.log(".");
        console.log("***********************************************");
        console.log("Liquidation results in ETH: ");

        // END TODO
    }

    /*
    Ref: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/using-flash-swaps
    
    For the sake of example, let's assume that we're dealing with a DAI/WETH pair, where DAI is WETH_address and WETH is debtAsset_USDT. 
    amount0Out and amount1Out specify the amount of DAI and WETH that the msg.sender wants the pair to send to the to address (one of these amounts may be 0). 
    At this point you may be wondering how the contract receives debtAsset_USDTs. For a typical (non-flash) swap, it's actually the responsibility of msg.sender to ensure 
    that enough WETH or DAI has already been sent to the pair before swap is called (in the context of trading, this is all handled neatly by a router contract). 
    But when executing a flash swap, debtAsset_USDTs do not need to be sent to the contract before calling swap. Instead, they must be sent from within a callback function 
    hat the pair triggers on the to address.
    */

    // https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
    // After the flashloan is created the below function will be called back by Uniswap
    // Uniswap is expecting the function to be named uniswapV2Call 
    // the parameters below will be sent
    // sender is the smart contract address
    // amount will be the amount borrowed from the flashloan and other amount will be 0
    // bytes is the calldata passed in above

    // required by the swap
    function uniswapV2Call(
        address ,
        uint256 amount0,
        uint256 amount1,
        bytes calldata
    ) external override {
        // TODO: implement your liquidation logic

        // 2.0. security checks and initializing variables
        //    *** Your code here ***
   
        console.log("**********************************************************");
        // console.log("tx.origin :", tx.origin);
        // console.log("address(this) :", address(this));
        console.log("**********************************************************");

        // Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleFlashSwap.sol
        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/ 
        address[] memory pathWETHUSTD = new address[](2);
        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
        // get the amount of debtAsset_USDTs that were borrowed in the flash loan amount 0 or amount 1 
        // call it amountTokenBorrowed and will use later in the function 
        uint256 amountTokenBorrowed = amount0 == 0 ? amount1 : amount0; 
        console.log("**********************************************************");
        console.log("amountTokenBorrowed :", amountTokenBorrowed);
        console.log("**********************************************************");
        // 2.1 liquidate the target user
        //    *** Your code here ***
        // ******************************************************************
        //we should borrow USDT
        // ******************************************************************
        
        // Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleFlashSwap.sol
        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/

        // make sure the call to this function originated from one of the pair contracts in uniswap to prevent unauthorized behavior
        require(msg.sender == IUniswapV2Factory(factory).getPair(WETH_address, debtAsset_USDT), 'Invalid Request for Uniswap address');

        // make sure one of the amounts = 0 
        require(amount0 == 0 || amount1 == 0, "Require one of the amounts are 0"); // this strategy is unidirectional
        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
        // Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleFlashSwap.sol
        // create and populate path array for sushiswap.  
        // this defines what debtAsset_USDT we are buying or selling 
        // if amount0 == 0 then we are going to sell debtAsset_USDT 1 and buy debtAsset_USDT 0 on sushiswap 
        // if amount0 is not 0 then we are going to sell debtAsset_USDT 0 and buy debtAsset_USDT 1 on sushiswap 
        
        pathWETHUSTD[0] = amount0 == 0 ? debtAsset_USDT : WETH_address; 
        pathWETHUSTD[1] = amount0 == 0 ? WETH_address : debtAsset_USDT; 
        
        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
        // create a pointer to the debtAsset_USDT we are going to sell on sushiswap 
        IERC20 USDTToken = IERC20(debtAsset_USDT);
        IERC20 WETHToken = IERC20(WETH_address);
        IERC20 WBTCToken = IERC20(collateralAddress_WBTC);

        // Use the given getReserves() function
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
        // (reserve0,reserve1,blockTimestampLast) = IUniswapV2Pair(pairWBTCUSDTAddress).getReserves();
        (reserve0,reserve1,blockTimestampLast) = IUniswapV2Pair(pairWETHUSDTAddress).getReserves();
        // console.log("WBTC reserve0 :",reserve0);
        console.log("WETH reserve0 :",reserve0);
        console.log("USDT reserve1 :",reserve1);
        console.log("blockTimestampLast :",blockTimestampLast);

        // calculate the amount of debtAsset_USDTs we need to reimburse uniswap for the flashloan 
        uint amountRequired = getAmountIn(amount1,reserve0,reserve1); // amount in XBTC as amount1 is in USDT
        console.log("amountRequired after getAmountIn() :",amountRequired);
        // ******************************************************************
        //liquidate the target user and get the WBTC
        // ******************************************************************

        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
        // approve the sushiSwapRouter to spend our debtAsset_USDTs so the trade can occur    
        // debtAsset_USDT.approve(address(sushiSwapRouter), amountTokenBorrowed);    

        // approve Aave Lending Pool to spend our USDT debtAsset_USDTs (debtAsset_USDT) so the trade can occur     
        USDTToken.approve(AavelendingPoolAddressProvider, amountTokenBorrowed);

        console.log("**********************************************************");
        console.log("USDT allowance to AavelendingPoolAddressProvider: ",USDTToken.allowance(address(this), AavelendingPoolAddressProvider));
        console.log("**********************************************************");

        // Liquidate loans

        // *****************************************************************************************************************************
        // Aave liquidation
        // Ref: https://mcl-docs.multiplier.finance/developers/api-reference/liquidations
       /* To trigger a liquidation on Aave, you need to call a public function liquidationCall provided by the Aave smart contracts. 
       In the function, you can specify 
       user representing the borrowing position you would like to liquidate, 
       debtAsset, the cryptocurrency you would like to repay (let's say debtAsset_USDT D), 
       and collateralAsset, the collateral cryptocurrency you would like claim from the borrowing position (let's say debtAsset_USDT C). 
       You also specify the amount of debt you want to repay, debtToCover.

        function liquidationCall(
            address collateralAsset, // Token C
            address debtAsset, // Token D
            address user,
            uint256 debtToCover,
            bool receiveAToken
        ) external;
        
        By calling this function, you then repay some amount of debtAsset_USDT D to Aave
         and in return, some debtAsset_USDT C is sent to your account.

        You should make sure that the user is in a liquidatable state. 
        Otherwise, the aave smart contract would revert your transaction and you would pay transaction fees for an unsuccessful liquidation.
        */
        /*
        ILendingPoolAddressesProvider addressProvider = ILendingPoolAddressesProvider(lendingPoolAddressProvider);
  
        ILendingPool lendingPool = ILendingPool(addressProvider.getLendingPool());
        
        require(IERC20(_reserve).approve(address(lendingPool), _purchaseAmount), "Approval error");
        // Assumes this contract already has `_purchaseAmount` of `_reserve`.
        lendingPool.liquidationCall(_collateral, _reserve, _user, _purchaseAmount, _receiveMToken);
         */
        // *****************************************************************************************************************************
        console.log("user :", user);
        console.log("receiveAToken:", receiveAToken);

        console.log("amountTokenBorrowed:", amountTokenBorrowed);

        // Record balance before liquidation
        uint256 WETH_balance = WETHToken.balanceOf(address(this));
        uint256 USDT_balance = USDTToken.balanceOf(address(this));
        uint256 WBTC_balance = WBTCToken.balanceOf(address(this));

        console.log("**********************************************************");
        console.log("WBTC_balance before liquidation:",WBTC_balance);
        console.log("WETH_balance before liquidation:",WETH_balance);
        console.log("USDT_balance before liquidation:",USDT_balance);
        console.log("**********************************************************");
        
        // console.log("msg.sender balance before :",IERC20(msg.sender).balanceOf(msg.sender));

        // Liquidation
        // Error code meaning @ https://etherscan.io/contractdiffchecker?a1=0x57Dcb9799E4F49EeE4974296023c81fA96f49335
        ILendingPool(AavelendingPoolAddressProvider).liquidationCall(collateralAddress_WBTC,debtAsset_USDT,user,amountTokenBorrowed,receiveAToken); //Liquidate USDT for WBTC
        
        // Record balance after liquidation
        WETH_balance = WETHToken.balanceOf(address(this));
        USDT_balance = USDTToken.balanceOf(address(this));
        WBTC_balance = WBTCToken.balanceOf(address(this));

        console.log("**********************************************************");
        console.log("WBTC_balance after liquidation:",WBTC_balance);
        console.log("WETH_balance after liquidation:",WETH_balance);
        console.log("USDT_balance after liquidation:",USDT_balance);
        console.log("**********************************************************");

        require(WBTC_balance > 0, "Fail as amountReceived <=0"); // fail if we didn't get XBTC from Aave liquidation
       
        // ******************************************************************
        // 2.2 swap WBTC for other things or repay directly
        // ******************************************************************

        // swap WBTC from liquidation to WETH using uniswap
        
        // Create pair address for WBTC for receipt and WETH for swap out in uniswap
        address[] memory pathWBTCWETH = new address[](2);
        pathWBTCWETH[0] = collateralAddress_WBTC;
        pathWBTCWETH[1] = WETH_address;               
        
        // construct uniswapRouter class variable
        pairWBTCWETHAddress = IUniswapV2Factory(factory).getPair(collateralAddress_WBTC, WETH_address);
        require(pairWBTCWETHAddress != address(0), 'Could not find pool on uniswap'); 
        console.log("Uniswap pairWBTCWETHAddress :", pairWBTCWETHAddress);
        
        uniswapRouter = IUniswapV2Router02(UNISWAP_ADDRESS_ROUTER);

        // Use the given getReserves() function
        // (reserve0,reserve1,blockTimestampLast) = IUniswapV2Pair(pairWBTCUSDTAddress).getReserves();
        (reserve0,reserve1,blockTimestampLast) = IUniswapV2Pair(pairWBTCWETHAddress).getReserves();
        // console.log("WBTC reserve0 :",reserve0);
        console.log("WBTC reserve0 :",reserve0);
        console.log("WETH reserve1 :",reserve1);
        console.log("blockTimestampLast :",blockTimestampLast);

        // trade deadline used for expiration
        uint256 deadline = block.timestamp + 300;

        // Approve WBTC to send by uniswap
        WBTCToken.approve(UNISWAP_ADDRESS_ROUTER, WBTCToken.balanceOf(address(this)));
        console.log("WBTC allowance to pairWBTCWETHAddress: ",WBTCToken.allowance(address(this), UNISWAP_ADDRESS_ROUTER));

        // swap WBTC to ETH and send back ETH to the msg.sender!
        /*
        Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH, and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).

        If the to address is a smart contract, it must have the ability to receive ETH.
        
        Name: Type	
        amountIn: uint	The amount of input tokens to send.
        amountOutMin: uint	The minimum amount of output tokens that must be received for the transaction not to revert.
        path: address[] calldata	An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
        to: address	Recipient of the ETH.
        deadline: uint	Unix timestamp after which the transaction will revert.
        amounts: uint[] memory	The input token amount and all subsequent output token amounts.
        */
        uniswapRouter.swapExactTokensForTokens(WBTCToken.balanceOf(address(this)), 0, pathWBTCWETH, address(this), deadline);

        // Record balance after WBTC WETH swap
        WETH_balance = WETHToken.balanceOf(address(this));
        USDT_balance = USDTToken.balanceOf(address(this));
        WBTC_balance = WBTCToken.balanceOf(address(this));

        console.log("**********************************************************");
        console.log("WBTC_balance after swap:",WBTC_balance);
        console.log("WETH_balance after swap:",WETH_balance);
        console.log("USDT_balance after swap:",USDT_balance);
        console.log("**********************************************************");

        require(WETH_balance >= amountRequired, "Fail as WETH swapped to less than amount required to repaid uniswap"); // fail if we didn't get XBTC

        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/

        // finally sell the debtAsset_USDT we borrowed from uniswap on sushiswap 
        // amountTokenBorrowed is the amount to sell 
        // amountRequired is the minimum amount of debtAsset_USDT to receive in exchange required to payback the flash loan 
        // path what we are selling or buying 
        // msg.sender address to receive the debtAsset_USDTs 
        // deadline is the order time limit 
        // if the amount received does not cover the flash loan the entire transaction is reverted 

        // ******************************************************************
        // 2.3 repay
        // ******************************************************************
        //    *** Your code here ***
        // Ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleFlashSwap.sol

        // pointer to output debtAsset_USDT from sushiswap 
        
        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
        // amount to payback flashloan 
        // amountRequired is the amount we need to payback 
        // uniswap can accept any debtAsset_USDT as payment

        // Note: msg.sender is uniswap!
        WETHToken.transfer(msg.sender, amountRequired); // return WETH to V2 pair to repay USDT flash loan. 
        // Ref: https://cryptomarketpool.com/flash-loan-arbitrage-on-uniswap-and-sushiswap/
        
        console.log("**********************************************************");
        console.log("WBTC_balance after paying back uniswap:",WBTC_balance);
        console.log("WETH_balance after paying back uniswap:",WETH_balance);
        console.log("USDT_balance after paying back uniswap:",USDT_balance);
        console.log("**********************************************************");

        // END TODO
    }
}
