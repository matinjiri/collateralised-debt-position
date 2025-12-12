// SPDX-License-Identifier: MIT
/// core.sol -- sBTC CDP database

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
    uint256 public debts; // Total sBTC Issued  [wad]
    uint256 public spot; // Price with Safety Margin  [ray]
    uint256 public vice; // Total Unbacked sBTC  [rad]

    struct Vault {
        uint256 coll; // Locked Collateral  [wad]
        uint256 debt; // Debt    [wad]
    }

    mapping(address => Vault) public vaults;
    mapping(address => uint) public gem; // available collateral e.g gem[usr] = 100USD [wad]
    mapping(address => uint) public sBTC; // [rad]

    constructor() {
        wards[msg.sender] = 1;
    }

    // --- Math ---
    string private constant ARITHMETIC_ERROR =
        string(abi.encodeWithSignature("Panic(uint256)", 0x11));

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function _add(uint256 x, int256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + uint256(y);
        }
        require(y >= 0 || z <= x, ARITHMETIC_ERROR);
        require(y <= 0 || z >= x, ARITHMETIC_ERROR);
    }
    function _mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := and(x, y)
        }
    }
    function _sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - uint256(y);
        }
        require(y <= 0 || z <= x, ARITHMETIC_ERROR);
        require(y >= 0 || z >= x, ARITHMETIC_ERROR);
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(x, y)
        }
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if (what == "spot") spot = data;
        else revert("Core/file-unrecognized-param");
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

    // Transfer User's sBTC
    function move(address src, address dst, uint256 rad) external {
        require(wish(src, msg.sender), "Core/not-allowed");
        sBTC[src] = sBTC[src] - rad;
        sBTC[dst] = sBTC[dst] + rad;
    }

    // --- CDP Manipulation ---
    function frob(address u, address v, address w, int dcoll, int ddebt) external {

        Vault memory vault = vaults[u];

        require(spot != 0, "Core/market-not-init");

        vault.coll = _add(vault.coll, dcoll);
        vault.debt = _add(vault.debt, ddebt);

        // vault is either less risky than before, or it is safe
        require(either(both(ddebt <= 0, dcoll >= 0), vault.debt <= vault.coll * spot / RAY), "Core/not-safe");

        // vault is either more safe, or the owner consents
        require(either(both(dcoll <= 0, ddebt >= 0), wish(u, msg.sender)), "Core/not-allowed-u");
        // collateral src consents
        require(either(dcoll <= 0, wish(v, msg.sender)), "Core/not-allowed-v");
        // debt dst consents
        require(either(ddebt >= 0, wish(w, msg.sender)), "Core/not-allowed-w");

        gem[v]  = _sub(gem[v], dcoll);
        sBTC[w] = _add(sBTC[w], _mul(RAY, ddebt));

        vaults[u] = vault;
        debts = _add(debts, ddebt);

    }

    // --- CDP Confiscation ---
    function grab(address u, address v, int dcoll, int ddebt) external auth {
        Vault storage vault = vaults[u];

        vault.coll = _add(vault.coll, dcoll);
        vault.debt = _add(vault.debt, ddebt);
        debts = _add(debts, ddebt);

        gem[v] = _sub(gem[v], dcoll);
        vice   = _sub(vice, _mul(RAY, ddebt));
    }
}
