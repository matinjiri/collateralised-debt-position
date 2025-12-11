// SPDX-License-Identifier: AGPL-3.0-or-later

/// dog.sol -- liquidation module 2.0

pragma solidity ^0.8.13;

interface CoreLike {
    function spot()
        external
        view
        returns (
            uint256 spot
        );
    function vaults(
        address
    )
        external
        view
        returns (
            uint256 coll, // [wad]
            uint256 debt // [wad]
        );
    function grab(address, address, int256, int256) external;
}

contract Dog {
    // --- Auth ---
    mapping(address => uint256) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
    }
    modifier auth() {
        require(wards[msg.sender] == 1, "Dog/not-authorized");
        _;
    }

    CoreLike public immutable core; // CDP Engine
    address public liquidator;

    uint256 public Dirt; // Amt sBTC needed to cover debt [wad]

    // --- Init ---
    constructor(address core_, address liquidator_) {
        core = CoreLike(core_);
        liquidator = liquidator_;
        wards[msg.sender] = 1;
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- CDP Liquidation ---
    function bark(
        address vault
    ) external {
        (uint256 coll, uint256 debt) = core.vaults(vault);

        {
            uint256 spot = core.spot();
            require(
                spot > 0 && mul(coll, spot) < mul(debt, RAY),
                "Dog/not-unsafe"
            );
        }

        require(coll > 0, "Dog/null-liquidation");
        require(debt <= 2 ** 255 && coll <= 2 ** 255, "Dog/overflow");

        core.grab(
            vault,
            liquidator,
            -int256(coll),
            -int256(debt)
        );
        
        Dirt = add(Dirt, debt);
    }
}
