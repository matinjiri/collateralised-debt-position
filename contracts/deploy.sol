// SPDX-License-Identifier: MIT
/// deploy.sol -- deploy module
pragma solidity ^0.8.28;

import "./core.sol";
import "./dog.sol";
import "./token.sol";
import {Spotter} from "./spot.sol";
import {GemJoin, SBTCJoin} from "./join.sol";

contract deploy {
    // --- Auth ---
    address public owner;
    modifier auth() {
        require(msg.sender == owner, "Core/not-authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    Core public core;
    SyntheticBitcoin public sBTC;
    SBTCJoin public sBTCJoin;
    Spotter public spotter;
    Dog public dog;
    GemJoin public ethJoin;

    function newCore() public returns (Core _core) {
        _core = new Core();
        _core.rely(owner);
        _core.deny(address(this));
    }

    function newDog(address _core) public returns (Dog _dog) {
        _dog = new Dog(_core, owner);
        _dog.rely(owner);
        _dog.deny(address(this));
    }

    function newSyntheticBitcoin() public returns (SyntheticBitcoin _syntheticBitcoin) {
        _syntheticBitcoin = new SyntheticBitcoin();
        _syntheticBitcoin.rely(owner);
        _syntheticBitcoin.deny(address(this));
    }

    function newSBtcJoin(
        address _core,
        address _sBTC
    ) public returns (SBTCJoin _syntheticBitcoin) {
        _syntheticBitcoin = new SBTCJoin(_core, _sBTC);
    }

    function newEthJoin(
        address _core,
        address weth
    ) public returns (GemJoin _ethJoin) {
        _ethJoin = new GemJoin(_core, "ETH", weth);
    }

    function newSpotter(
        address _core,
        address priceFeed
    ) public returns (Spotter _spotter) {
        _spotter = new Spotter(_core, priceFeed);
        _spotter.rely(owner);
        _spotter.deny(address(this));
    }
    
    function addContracts(address priceFeed, address weth) public auth {
        core = newCore();
        dog = newDog(address(core));
        sBTC = newSyntheticBitcoin();
        sBTCJoin = newSBtcJoin(address(core), address(sBTC));
        spotter = newSpotter(address(core), priceFeed);
        ethJoin = newEthJoin(address(core), weth);
    }

    function enableAccesses() public auth {
        core.rely(address(dog));
        core.rely(address(sBTCJoin));
        core.rely(address(spotter));
        core.rely(address(ethJoin));
        sBTC.rely(address(sBTCJoin));
    }

    function updateAndPoke() public auth {
        spotter.file("mat", 1500000000000000000000000000); // 150%
        spotter.poke();
    }
}
