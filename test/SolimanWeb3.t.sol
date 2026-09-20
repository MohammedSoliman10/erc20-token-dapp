// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/SolimanWeb3.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract SolimanWeb3Test is Test {
    SolimanWeb3 public token;
    address public owner;
    address public alice;
    address public bob;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant CAP = 1_000_000 ether;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        token = new SolimanWeb3("SollyWeb3", "MS3", CAP);
    }

    // ------------------------------
    // constructor

    function test_constructor_setsName() public view {
        assertEq(token.name(), "SollyWeb3");
    }

    function test_constructor_setsSymbol() public view {
        assertEq(token.symbol(), "MS3");
    }

    function test_constructor_zeroInitialSupply() public view {
        assertEq(token.totalSupply(), 0);
    }

    function test_decimals() public view {
        assertEq(token.decimals(), 18);
    }

    function test_constructor_setsCap() public view {
        assertEq(token.cap(), CAP);
    }

    function test_constructor_revertIfZeroCap() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20Capped.ERC20InvalidCap.selector, 0));
        new SolimanWeb3("Zero", "ZERO", 0);
    }

    function test_constructor_grantsRolesToDeployer() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(token.hasRole(MINTER_ROLE, owner));
        assertTrue(token.hasRole(PAUSER_ROLE, owner));
    }

    ///////////////////////////////////
    // mint

    function test_mint_asMinter() public {
        token.mint(alice, 1000 ether);
        assertEq(token.balanceOf(alice), 1000 ether);
        assertEq(token.totalSupply(), 1000 ether);
    }

    function test_mint_toMultipleAddresses() public {
        token.mint(alice, 500 ether);
        token.mint(bob, 300 ether);
        assertEq(token.balanceOf(alice), 500 ether);
        assertEq(token.balanceOf(bob), 300 ether);
        assertEq(token.totalSupply(), 800 ether);
    }

    function test_mint_revertIfNotMinter() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, MINTER_ROLE)
        );
        token.mint(alice, 1000 ether);
    }

    function test_mint_revertIfMintToZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.mint(address(0), 1000e18);
    }

    function test_mint_revertIfExceedsCap() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20Capped.ERC20ExceededCap.selector, CAP + 1, CAP));
        token.mint(alice, CAP + 1);
    }

    function test_mint_upToCapSucceeds() public {
        token.mint(alice, CAP);
        assertEq(token.totalSupply(), CAP);
    }

    function test_mint_grantedMinterCanMint() public {
        token.grantRole(MINTER_ROLE, alice);
        vm.prank(alice);
        token.mint(bob, 100 ether);
        assertEq(token.balanceOf(bob), 100 ether);
    }

    function testFuzz_mint(uint256 amount) public {
        amount = bound(amount, 1, CAP);
        token.mint(alice, amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), amount);
    }

    ////////////////
    // transfer

    function test_transfer_success() public {
        token.mint(alice, 1000e18);
        vm.prank(alice);
        bool ok = token.transfer(bob, 400e18);
        assertTrue(ok);
        assertEq(token.balanceOf(alice), 600e18);
        assertEq(token.balanceOf(bob), 400e18);
    }

    function test_transfer_revertInsufficientBalance() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 100e18, 200e18));
        token.transfer(bob, 200e18);
    }

    function test_transfer_revertToZeroAddress() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.transfer(address(0), 50e18);
    }

    function test_transfer_emitsEvent() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(alice, bob, 50e18);
        token.transfer(bob, 50e18);
    }

    function testFuzz_transfer(uint256 amount, uint256 mintAmount) public {
        mintAmount = bound(mintAmount, 1, CAP);
        amount = bound(amount, 0, mintAmount);
        token.mint(alice, mintAmount);
        vm.prank(alice);
        token.transfer(bob, amount);
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(alice), mintAmount - amount);
    }

    ////////////////////////////////
    // erc20 : approve and allowance

    function test_approve_success() public {
        vm.prank(alice);
        bool ok = token.approve(bob, 500e18);
        assertTrue(ok);
        assertEq(token.allowance(alice, bob), 500e18);
    }

    function test_approve_overwrite() public {
        vm.prank(alice);
        token.approve(bob, 500e18);
        vm.prank(alice);
        token.approve(bob, 200e18);
        assertEq(token.allowance(alice, bob), 200e18);
    }

    function test_approve_revertSpenderZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        token.approve(address(0), 100e18);
    }

    function test_approve_emitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(alice, bob, 300e18);
        token.approve(bob, 300e18);
    }

    //////////////////////////////////
    // transferfrom

    function test_transferFrom_success() public {
        token.mint(alice, 1000e18);
        vm.prank(alice);
        token.approve(bob, 500e18);

        vm.prank(bob);
        bool ok = token.transferFrom(alice, bob, 300e18);
        assertTrue(ok);
        assertEq(token.balanceOf(alice), 700e18);
        assertEq(token.balanceOf(bob), 300e18);
        assertEq(token.allowance(alice, bob), 200e18); // 500 - 300
    }

    function test_transferFrom_revertInsufficientAllowance() public {
        token.mint(alice, 1000e18);
        vm.prank(alice);
        token.approve(bob, 100e18);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 100e18, 200e18));
        token.transferFrom(alice, bob, 200e18);
    }

    function test_transferFrom_infiniteApproval() public {
        token.mint(alice, 1000e18);
        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.transferFrom(alice, bob, 500e18);
        // Allowance should remain max (not decrease)
        assertEq(token.allowance(alice, bob), type(uint256).max);
    }

    function test_transferFrom_revertToZeroAddress() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        token.approve(bob, 100e18);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.transferFrom(alice, address(0), 50e18);
    }

    //////////////////////////////////////
    // burn / burnFrom

    function test_burn_success() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        token.burn(40e18);
        assertEq(token.balanceOf(alice), 60e18);
        assertEq(token.totalSupply(), 60e18);
    }

    function test_burn_revertInsufficientBalance() public {
        token.mint(alice, 10e18);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 10e18, 20e18));
        token.burn(20e18);
    }

    function test_burnFrom_success() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        token.approve(bob, 50e18);

        vm.prank(bob);
        token.burnFrom(alice, 30e18);
        assertEq(token.balanceOf(alice), 70e18);
        assertEq(token.allowance(alice, bob), 20e18);
    }

    function test_burnFrom_revertInsufficientAllowance() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        token.approve(bob, 10e18);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 10e18, 20e18));
        token.burnFrom(alice, 20e18);
    }

    function test_mintAfterBurn_respectsCap() public {
        token.mint(alice, CAP);
        vm.prank(alice);
        token.burn(100 ether);
        // supply is now below cap, minting the freed-up room should succeed
        token.mint(bob, 100 ether);
        assertEq(token.totalSupply(), CAP);
    }

    //////////////////////////////////////
    // pause / unpause

    function test_pause_asPauser() public {
        token.pause();
        assertTrue(token.paused());
    }

    function test_pause_revertIfNotPauser() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, PAUSER_ROLE)
        );
        token.pause();
    }

    function test_transfer_revertWhenPaused() public {
        token.mint(alice, 100e18);
        token.pause();
        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        token.transfer(bob, 10e18);
    }

    function test_mint_revertWhenPaused() public {
        token.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        token.mint(alice, 10e18);
    }

    function test_unpause_restoresTransfers() public {
        token.mint(alice, 100e18);
        token.pause();
        token.unpause();
        assertFalse(token.paused());
        vm.prank(alice);
        bool ok = token.transfer(bob, 10e18);
        assertTrue(ok);
    }

    function test_unpause_revertIfNotPauser() public {
        token.pause();
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, PAUSER_ROLE)
        );
        token.unpause();
    }

    //////////////////////////////////////
    // AccessControl: roles

    function test_grantRole_asAdmin() public {
        token.grantRole(MINTER_ROLE, alice);
        assertTrue(token.hasRole(MINTER_ROLE, alice));
    }

    function test_grantRole_revertIfNotAdmin() public {
        bytes32 adminRole = token.DEFAULT_ADMIN_ROLE();
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, adminRole)
        );
        token.grantRole(MINTER_ROLE, bob);
    }

    function test_revokeRole_asAdmin() public {
        token.grantRole(MINTER_ROLE, alice);
        token.revokeRole(MINTER_ROLE, alice);
        assertFalse(token.hasRole(MINTER_ROLE, alice));

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, MINTER_ROLE)
        );
        token.mint(bob, 1e18);
    }

    function test_renounceRole_self() public {
        token.renounceRole(MINTER_ROLE, owner);
        assertFalse(token.hasRole(MINTER_ROLE, owner));

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, owner, MINTER_ROLE)
        );
        token.mint(alice, 1e18);
    }

    //////////////////////////////////////
    // ERC20Permit (EIP-2612)

    function test_permit_success() public {
        uint256 alicePk = 0xA11CE;
        address aliceAcc = vm.addr(alicePk);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                aliceAcc,
                bob,
                500e18,
                token.nonces(aliceAcc),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);

        token.permit(aliceAcc, bob, 500e18, deadline, v, r, s);
        assertEq(token.allowance(aliceAcc, bob), 500e18);
        assertEq(token.nonces(aliceAcc), 1);
    }

    function test_permit_revertExpiredDeadline() public {
        uint256 alicePk = 0xA11CE;
        address aliceAcc = vm.addr(alicePk);
        uint256 deadline = block.timestamp == 0 ? 0 : block.timestamp - 1;

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                aliceAcc,
                bob,
                500e18,
                token.nonces(aliceAcc),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);

        vm.expectRevert(abi.encodeWithSignature("ERC2612ExpiredSignature(uint256)", deadline));
        token.permit(aliceAcc, bob, 500e18, deadline, v, r, s);
    }

    function test_permit_revertInvalidSigner() public {
        uint256 alicePk = 0xA11CE;
        uint256 wrongPk = 0xBAD;
        address aliceAcc = vm.addr(alicePk);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                aliceAcc,
                bob,
                500e18,
                token.nonces(aliceAcc),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPk, digest);

        vm.expectRevert(abi.encodeWithSignature("ERC2612InvalidSigner(address,address)", vm.addr(wrongPk), aliceAcc));
        token.permit(aliceAcc, bob, 500e18, deadline, v, r, s);
    }
}
