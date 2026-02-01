//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test} from "forge-std/Test.sol";

contract OurTokenTest is Test {
    OurToken ourToken;
    DeployOurToken deployer;

    address gohan = makeAddr("gohan");
    address pan = makeAddr("pan");
    address goku = makeAddr("goku");

    uint256 public constant STARTING_BALANCE = 120 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(gohan, STARTING_BALANCE);
    }

    function testGohanBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(gohan));
    }

    function testAllowances() public {
        uint256 initialAllowances = 1500;
        vm.prank(gohan);
        ourToken.approve(pan, initialAllowances); //only approval no token transfer

        uint256 transferAmount = 30;
        vm.prank(pan);
        ourToken.transferFrom(gohan, pan, transferAmount); //transfer to approved person

        assertEq(transferAmount, ourToken.balanceOf(pan));
        assertEq(ourToken.balanceOf(gohan), STARTING_BALANCE - transferAmount);
    }

    // ============================================
    // NEW TESTS - TOKEN METADATA
    // ============================================

    function testTokenName() public view {
        assertEq(ourToken.name(), "OurToken");
    }

    function testTokenSymbol() public view {
        assertEq(ourToken.symbol(), "OTk");
    }

    function testDecimals() public view {
        assertEq(ourToken.decimals(), 18);
    }

    function testTotalSupply() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    // ============================================
    // NEW TESTS - TRANSFERS
    // ============================================

    function testTransferUpdatesBalances() public {
        uint256 transferAmount = 50 ether;

        vm.prank(gohan);
        ourToken.transfer(pan, transferAmount);

        assertEq(ourToken.balanceOf(gohan), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(pan), transferAmount);
    }

    function testTransferEmitsEvent() public {
        uint256 transferAmount = 50 ether;

        vm.prank(gohan);
        vm.expectEmit(true, true, false, true);
        emit Transfer(gohan, pan, transferAmount);
        ourToken.transfer(pan, transferAmount);
    }

    function testTransferToZeroAddressFails() public {
        vm.prank(gohan);
        vm.expectRevert();
        ourToken.transfer(address(0), 100 ether);
    }

    function testTransferInsufficientBalanceFails() public {
        uint256 tooMuch = STARTING_BALANCE + 1;

        vm.prank(gohan);
        vm.expectRevert();
        ourToken.transfer(pan, tooMuch);
    }

    function testTransferZeroAmount() public {
        vm.prank(gohan);
        bool success = ourToken.transfer(pan, 0);

        assertTrue(success);
        assertEq(ourToken.balanceOf(gohan), STARTING_BALANCE);
        assertEq(ourToken.balanceOf(pan), 0);
    }

    // ============================================
    // NEW TESTS - APPROVALS
    // ============================================

    function testApprovalSetsAllowance() public {
        uint256 approvalAmount = 1000 ether;

        vm.prank(gohan);
        ourToken.approve(pan, approvalAmount);

        assertEq(ourToken.allowance(gohan, pan), approvalAmount);
    }

    function testApprovalEmitsEvent() public {
        uint256 approvalAmount = 1000 ether;

        vm.prank(gohan);
        vm.expectEmit(true, true, false, true);
        emit Approval(gohan, pan, approvalAmount);
        ourToken.approve(pan, approvalAmount);
    }

    function testApproveZeroAddress() public {
        vm.prank(gohan);
        vm.expectRevert();
        ourToken.approve(address(0), 100 ether);
    }

    function testMultipleApprovals() public {
        vm.startPrank(gohan);
        ourToken.approve(pan, 100 ether);
        ourToken.approve(goku, 200 ether);
        vm.stopPrank();

        assertEq(ourToken.allowance(gohan, pan), 100 ether);
        assertEq(ourToken.allowance(gohan, goku), 200 ether);
    }

    function testApprovalOverwrite() public {
        vm.startPrank(gohan);
        ourToken.approve(pan, 100 ether);
        ourToken.approve(pan, 50 ether); // Overwrite previous approval
        vm.stopPrank();

        assertEq(ourToken.allowance(gohan, pan), 50 ether);
    }

    // ============================================
    // NEW TESTS - TRANSFER FROM
    // ============================================

    function testTransferFromWithApproval() public {
        uint256 approvalAmount = 100 ether;
        uint256 transferAmount = 50 ether;

        vm.prank(gohan);
        ourToken.approve(pan, approvalAmount);

        vm.prank(pan);
        ourToken.transferFrom(gohan, goku, transferAmount);

        assertEq(ourToken.balanceOf(gohan), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(goku), transferAmount);
        assertEq(
            ourToken.allowance(gohan, pan),
            approvalAmount - transferAmount
        );
    }

    function testTransferFromReducesAllowance() public {
        uint256 approvalAmount = 100 ether;
        uint256 transferAmount = 30 ether;

        vm.prank(gohan);
        ourToken.approve(pan, approvalAmount);

        vm.prank(pan);
        ourToken.transferFrom(gohan, goku, transferAmount);

        assertEq(ourToken.allowance(gohan, pan), 70 ether);
    }

    function testTransferFromWithoutApprovalFails() public {
        vm.prank(pan);
        vm.expectRevert();
        ourToken.transferFrom(gohan, goku, 50 ether);
    }

    function testTransferFromExceedsAllowanceFails() public {
        vm.prank(gohan);
        ourToken.approve(pan, 50 ether);

        vm.prank(pan);
        vm.expectRevert();
        ourToken.transferFrom(gohan, goku, 51 ether);
    }

    function testTransferFromExceedsBalanceFails() public {
        vm.prank(gohan);
        ourToken.approve(pan, 200 ether);

        vm.prank(pan);
        vm.expectRevert();
        ourToken.transferFrom(gohan, goku, STARTING_BALANCE + 1);
    }

    function testTransferFromEmitsEvent() public {
        uint256 approvalAmount = 100 ether;
        uint256 transferAmount = 50 ether;

        vm.prank(gohan);
        ourToken.approve(pan, approvalAmount);

        vm.prank(pan);
        vm.expectEmit(true, true, false, true);
        emit Transfer(gohan, goku, transferAmount);
        ourToken.transferFrom(gohan, goku, transferAmount);
    }

    // ============================================
    // NEW TESTS - EDGE CASES
    // ============================================

    function testBalanceOfZeroAddress() public view {
        assertEq(ourToken.balanceOf(address(0)), 0);
    }

    function testAllowanceWithNoApproval() public view {
        assertEq(ourToken.allowance(gohan, pan), 0);
    }

    function testTransferToSelf() public {
        uint256 amount = 50 ether;
        uint256 initialBalance = ourToken.balanceOf(gohan);

        vm.prank(gohan);
        ourToken.transfer(gohan, amount);

        assertEq(ourToken.balanceOf(gohan), initialBalance);
    }

    function testMultipleTransfers() public {
        vm.startPrank(gohan);
        ourToken.transfer(pan, 20 ether);
        ourToken.transfer(goku, 30 ether);
        ourToken.transfer(pan, 10 ether);
        vm.stopPrank();

        assertEq(ourToken.balanceOf(gohan), STARTING_BALANCE - 60 ether);
        assertEq(ourToken.balanceOf(pan), 30 ether);
        assertEq(ourToken.balanceOf(goku), 30 ether);
    }

    // ============================================
    // NEW TESTS - FUZZ TESTING
    // ============================================

    function testFuzzTransfer(uint256 amount) public {
        // Bound amount between 0 and STARTING_BALANCE
        amount = bound(amount, 0, STARTING_BALANCE);

        vm.prank(gohan);
        ourToken.transfer(pan, amount);

        assertEq(ourToken.balanceOf(gohan), STARTING_BALANCE - amount);
        assertEq(ourToken.balanceOf(pan), amount);
    }

    function testFuzzApproval(uint256 amount) public {
        vm.prank(gohan);
        ourToken.approve(pan, amount);

        assertEq(ourToken.allowance(gohan, pan), amount);
    }

    function testFuzzTransferFrom(
        uint256 approvalAmount,
        uint256 transferAmount
    ) public {
        approvalAmount = bound(approvalAmount, 0, STARTING_BALANCE);
        transferAmount = bound(transferAmount, 0, approvalAmount);

        vm.prank(gohan);
        ourToken.approve(pan, approvalAmount);

        vm.prank(pan);
        ourToken.transferFrom(gohan, goku, transferAmount);

        assertEq(ourToken.balanceOf(goku), transferAmount);
        assertEq(
            ourToken.allowance(gohan, pan),
            approvalAmount - transferAmount
        );
    }

    // ============================================
    // NEW TESTS - DEPLOYMENT
    // ============================================

    function testDeployerReceivesInitialSupply() public {
        // Deploy a fresh token to test
        OurToken newToken = new OurToken(1000 ether);

        assertEq(newToken.balanceOf(address(this)), 1000 ether);
        assertEq(newToken.totalSupply(), 1000 ether);
    }

    function testInitialSupplyIsCorrect() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }
}
