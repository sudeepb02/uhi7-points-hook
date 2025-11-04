// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "src/PointsHook.sol";

import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

import {PointsHook} from "src/PointsHook.sol";

contract DeployHook is Script {
    address constant CREATE2_DEPLOYER =
        address(0x4e59b44847b379578588920cA78FbF26c0B4956C); // Unichain

    /// @dev Replace with the desired PoolManager on its corresponding chain
    IPoolManager constant POOLMANAGER =
        IPoolManager(address(0x1F98400000000000000000000000000000000004)); // Unichain

    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        string memory rpcUrl = vm.envString("UNICHAIN_RPC_URL");

        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);
        console.log("Hook flags:", flags);

        bytes memory constructorArgs = abi.encode(POOLMANAGER);

        // Mine a salt that will produce a hook address with the correct flags
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(PointsHook).creationCode,
            constructorArgs
        );

        // Deploy the hook using CREATE2
        vm.startBroadcast(privateKey);

        PointsHook hook = new PointsHook{salt: salt}(IPoolManager(POOLMANAGER));
        require(address(hook) == hookAddress, "hook address mismatch");

        console.log("Deployed PointsHook at address:", address(hook));

        vm.stopBroadcast();
    }
}
