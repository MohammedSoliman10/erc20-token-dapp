// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/SolimanWeb3.sol";

contract DeployScript is Script {
    // Defaults — override with env vars if you want different values at deploy time.
    string public constant NAME = "SollyWeb3";
    string public constant SYMBOL = "MS3";
    uint256 public constant CAP = 1_000_000 ether;

    function run() external returns (SolimanWeb3 token) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        token = new SolimanWeb3(NAME, SYMBOL, CAP);
        vm.stopBroadcast();

        console2.log("SolimanWeb3 deployed at:", address(token));
        console2.log("Name:", token.name());
        console2.log("Symbol:", token.symbol());
        console2.log("Cap:", token.cap());
    }
}
