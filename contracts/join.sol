// SPDX-License-Identifier: AGPL-3.0-or-later

/// join.sol -- Basic token adapters

pragma solidity ^0.8.13;

interface GemLike {
    function decimals() external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface ERC20Like {
    function mint(address, uint) external;
    function burn(address, uint) external;
}

interface CoreLike {
    function slip(address, int) external;
    function move(address, address, uint) external;
}

/*
    Here we provide *adapters* to connect the Core to arbitrary external
    token implementations, creating a bounded context for the Core. The
    adapters here are provided as working examples:

      - `GemJoin`: For well behaved ERC20 tokens, with simple transfer
                   semantics.

      - `sBTCJoin`: For connecting internal sBTC balances to an external
                    `Token` implementation.

    Adapters need to implement two basic methods:

      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system

*/

contract GemJoin {
    CoreLike public core; // CDP Engine
    bytes32 public market; // Collateral Type
    GemLike public gem;
    uint public dec;

    constructor(address core_, bytes32 market_, address gem_) {
        core = CoreLike(core_);
        market = market_;
        gem = GemLike(gem_);
    }

    function join(address usr, uint wad) external {
        require(int(wad) >= 0, "GemJoin/overflow");
        core.slip(usr, int(wad));
        require(
            gem.transferFrom(msg.sender, address(this), wad),
            "GemJoin/failed-transfer"
        );
    }

    function exit(address usr, uint wad) external {
        require(wad <= 2 ** 255, "GemJoin/overflow");
        core.slip(msg.sender, -int(wad));
        require(gem.transfer(usr, wad), "GemJoin/failed-transfer");
    }
}

contract sBTCJoin {
    CoreLike public core;   // CDP Engine
    ERC20Like public sBTC;  // Stablecoin Token

    constructor(address core_, address sBTC_) {
        core = CoreLike(core_);
        sBTC = ERC20Like(sBTC_);
    }

    uint constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function join(address usr, uint wad) external {
        core.move(address(this), usr, mul(ONE, wad));
        sBTC.burn(msg.sender, wad);
    }

    function exit(address usr, uint wad) external {
        core.move(msg.sender, address(this), mul(ONE, wad));
        sBTC.mint(usr, wad);
    }
}