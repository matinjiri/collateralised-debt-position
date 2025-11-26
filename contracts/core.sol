// SPDX-License-Identifier: MIT
/// core.sol -- sETH CDP database

pragma solidity ^0.8.28;

contract Core {
    // --- Auth ---
    mapping(address => uint) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
    }
    modifier auth() {
        require(wards[msg.sender] == 1, "Core/not-authorized");
        _;
    }

    mapping(address => mapping(address => uint)) public can;
    function hope(address usr) external {
        can[msg.sender][usr] = 1;
    }
    function nope(address usr) external {
        can[msg.sender][usr] = 0;
    }
    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    uint256 public debts; // Total sETH Issued  [wad]
    uint256 public spot; // Price with Safety Margin  [ray]

    struct Vault {
        uint256 coll; // Locked Collateral  [wad]
        uint256 debt; // Debt    [wad]
    }

    mapping(address => Vault) public vaults;
    mapping(address => uint) public gem; // available collateral e.g gem[usr] = 100USD [wad]
    mapping(address => uint) public sETH; // [rad]

    constructor() {
        wards[msg.sender] = 1;
    }

    // --- Math ---
    string private constant ARITHMETIC_ERROR =
        string(abi.encodeWithSignature("Panic(uint256)", 0x11));

    function _add(uint256 x, int256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + uint256(y);
        }
        require(y >= 0 || z <= x, ARITHMETIC_ERROR);
        require(y <= 0 || z >= x, ARITHMETIC_ERROR);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(x, y)
        }
    }

    // Join Collateral
    function slip(address usr, int256 wad) external auth {
        gem[usr] = _add(gem[usr], wad);
    }

    // Transfer User's Collateral
    function flux(address src, address dst, uint256 wad) external {
        require(wish(src, msg.sender), "Core/not-allowed");
        gem[src] = gem[src] - wad;
        gem[dst] = gem[dst] + wad;
    }

    // Transfer User's sETH
    function move(address src, address dst, uint256 rad) external {
        require(wish(src, msg.sender), "Core/not-allowed");
        sETH[src] = sETH[src] - rad;
        sETH[dst] = sETH[dst] + rad;
    }
}
