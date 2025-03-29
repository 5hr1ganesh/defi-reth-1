pragma solidity ^0.8;

import "lib/forge-std/src/Test.sol";

contract TestJson is Test {
    function test() public {
        vm.readFile("test/eigen-layer/root.json");
    }
}
