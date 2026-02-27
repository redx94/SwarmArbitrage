// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ============================================================
//  SwarmArbitrage — FlashArbitrage.sol
//  ============================================================
//  Atomic flash-loan arbitrage executor.
//  Supports:
//    - Aave V3 flash loans (zero-interest single block)
//    - Balancer V2 flash loans (zero-fee)
//    - Uniswap V2 / V3 swaps
//    - SushiSwap V2 swaps
//    - Curve pool swaps
//  All profit goes directly to owner.
// ============================================================

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ---- Interfaces ----

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

interface IAaveV3Pool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// Uniswap V2 Router
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// Uniswap V3 Router
interface IUniswapV3Router {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface IUniswapV3Quoter {
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut, uint160[] memory sqrtPriceX96AfterList, uint32[] memory initializedTicksCrossedList, uint256 gasEstimate);
}

// Curve
interface ICurvePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

// ===================================================================
//  MAIN CONTRACT
// ===================================================================

contract FlashArbitrage is Ownable, ReentrancyGuard, IFlashLoanReceiver {
    using SafeERC20 for IERC20;

    // ---- Swap route structs ----

    enum DexType { UniswapV2, UniswapV3, Curve, Balancer }

    struct SwapStep {
        DexType dexType;
        address router;       // router / pool address
        address tokenIn;
        address tokenOut;
        uint256 minAmountOut; // slippage protection
        bytes   extraData;    // encoded pool fee (V3) or curve indices
    }

    struct ArbitrageParams {
        address flashLoanToken;   // token to borrow
        uint256 flashLoanAmount;  // amount to borrow
        SwapStep[] steps;         // ordered swap path
        uint256 minProfit;        // abort if profit < minProfit (in flashLoanToken)
    }

    // ---- State ----

    IAaveV3Pool  public immutable aavePool;
    IBalancerVault public immutable balancerVault;

    mapping(address => bool) public approvedCallers; // swarm agents

    // ---- Events ----

    event ArbitrageExecuted(
        address indexed token,
        uint256 borrowed,
        uint256 profit,
        address indexed executor
    );
    event CallerUpdated(address indexed caller, bool approved);

    // ---- Modifiers ----

    modifier onlyApproved() {
        require(approvedCallers[msg.sender] || msg.sender == owner(), "Not approved");
        _;
    }

    // ---- Constructor ----

    constructor(address _aavePool, address _balancerVault) Ownable(msg.sender) {
        aavePool    = IAaveV3Pool(_aavePool);
        balancerVault = IBalancerVault(_balancerVault);
    }

    // ============================================================
    //  OWNER CONTROLS
    // ============================================================

    function setCallerApproval(address caller, bool approved) external onlyOwner {
        approvedCallers[caller] = approved;
        emit CallerUpdated(caller, approved);
    }

    /// Rescue any stuck tokens
    function rescueToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    function rescueETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // ============================================================
    //  ENTRY POINTS — called by off-chain bot
    // ============================================================

    /// Execute arbitrage using Aave V3 flash loan
    function executeAaveArbitrage(
        address flashToken,
        uint256 amount,
        SwapStep[] calldata steps,
        uint256 minProfit
    ) external onlyApproved nonReentrant {
        ArbitrageParams memory params = ArbitrageParams({
            flashLoanToken: flashToken,
            flashLoanAmount: amount,
            steps: steps,
            minProfit: minProfit
        });

        address[] memory assets  = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory modes   = new uint256[](1);
        assets[0]  = flashToken;
        amounts[0] = amount;
        modes[0]   = 0; // no debt mode

        aavePool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            abi.encode(params),
            0
        );
    }

    /// Execute arbitrage using Balancer V2 flash loan (zero fee)
    function executeBalancerArbitrage(
        address flashToken,
        uint256 amount,
        SwapStep[] calldata steps,
        uint256 minProfit
    ) external onlyApproved nonReentrant {
        ArbitrageParams memory params = ArbitrageParams({
            flashLoanToken: flashToken,
            flashLoanAmount: amount,
            steps: steps,
            minProfit: minProfit
        });

        address[] memory tokens  = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0]  = flashToken;
        amounts[0] = amount;

        balancerVault.flashLoan(
            address(this),
            tokens,
            amounts,
            abi.encode(params)
        );
    }

    // ============================================================
    //  FLASH LOAN CALLBACKS
    // ============================================================

    /// Aave V3 callback
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(aavePool), "Caller not Aave pool");
        require(initiator == address(this), "Bad initiator");

        ArbitrageParams memory ap = abi.decode(params, (ArbitrageParams));
        uint256 amountOwed = amounts[0] + premiums[0];

        _runArbitrage(ap, amountOwed);

        // Approve repayment
        IERC20(assets[0]).safeIncreaseAllowance(address(aavePool), amountOwed);
        return true;
    }

    /// Balancer V2 callback
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(msg.sender == address(balancerVault), "Caller not Balancer");

        ArbitrageParams memory ap = abi.decode(userData, (ArbitrageParams));
        uint256 amountOwed = amounts[0] + feeAmounts[0];

        _runArbitrage(ap, amountOwed);

        // Repay Balancer (just transfer back)
        IERC20(tokens[0]).safeTransfer(address(balancerVault), amountOwed);
    }

    // ============================================================
    //  CORE ARBITRAGE LOGIC
    // ============================================================

    function _runArbitrage(ArbitrageParams memory ap, uint256 amountOwed) internal {
        uint256 balanceBefore = IERC20(ap.flashLoanToken).balanceOf(address(this));

        // Execute every swap step in sequence
        uint256 currentAmount = ap.flashLoanAmount;
        for (uint256 i = 0; i < ap.steps.length; i++) {
            currentAmount = _executeSwap(ap.steps[i], currentAmount);
        }

        uint256 balanceAfter = IERC20(ap.flashLoanToken).balanceOf(address(this));

        // Safety checks
        require(balanceAfter >= amountOwed, "Cannot repay flash loan");

        uint256 profit = balanceAfter > amountOwed ? balanceAfter - amountOwed : 0;
        // Use balanceBefore in profit calc to avoid double-counting
        profit = balanceAfter >= (balanceBefore - ap.flashLoanAmount + amountOwed)
            ? balanceAfter - (balanceBefore - ap.flashLoanAmount + amountOwed)
            : 0;

        require(profit >= ap.minProfit, "Profit below minimum threshold");

        // Send profit to owner
        if (profit > 0) {
            IERC20(ap.flashLoanToken).safeTransfer(owner(), profit);
            emit ArbitrageExecuted(ap.flashLoanToken, ap.flashLoanAmount, profit, tx.origin);
        }
    }

    function _executeSwap(SwapStep memory step, uint256 amountIn) internal returns (uint256 amountOut) {
        IERC20(step.tokenIn).safeIncreaseAllowance(step.router, amountIn);

        if (step.dexType == DexType.UniswapV2) {
            amountOut = _swapV2(step, amountIn);
        } else if (step.dexType == DexType.UniswapV3) {
            amountOut = _swapV3(step, amountIn);
        } else if (step.dexType == DexType.Curve) {
            amountOut = _swapCurve(step, amountIn);
        } else {
            revert("Unknown DEX type");
        }
    }

    function _swapV2(SwapStep memory step, uint256 amountIn) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = step.tokenIn;
        path[1] = step.tokenOut;

        uint256[] memory amounts = IUniswapV2Router(step.router).swapExactTokensForTokens(
            amountIn,
            step.minAmountOut,
            path,
            address(this),
            block.timestamp + 30
        );
        return amounts[amounts.length - 1];
    }

    function _swapV3(SwapStep memory step, uint256 amountIn) internal returns (uint256) {
        // extraData = abi.encoded V3 path bytes (tokenIn/fee/tokenOut)
        bytes memory path = step.extraData.length > 0
            ? step.extraData
            : abi.encodePacked(step.tokenIn, uint24(3000), step.tokenOut);

        return IUniswapV3Router(step.router).exactInput(
            IUniswapV3Router.ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp + 30,
                amountIn: amountIn,
                amountOutMinimum: step.minAmountOut
            })
        );
    }

    function _swapCurve(SwapStep memory step, uint256 amountIn) internal returns (uint256) {
        // extraData = abi.encode(int128 i, int128 j)
        (int128 i, int128 j) = abi.decode(step.extraData, (int128, int128));
        return ICurvePool(step.router).exchange(i, j, amountIn, step.minAmountOut);
    }

    // ---- ETH receive fallback ----
    receive() external payable {}
}
