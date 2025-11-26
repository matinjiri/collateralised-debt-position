// SPDX-License-Identifier: AGPL-3.0-or-later

/// sETH.sol -- sETH Stablecoin ERC-20 Token

pragma solidity ^0.8.13;

contract SyntheticEthereum {
    // --- Auth ---
    mapping(address => uint) public wards;
    function rely(address guy) external auth {
        wards[guy] = 1;
    }
    function deny(address guy) external auth {
        wards[guy] = 0;
    }
    modifier auth() {
        require(wards[msg.sender] == 1, "SyntheticEthereum/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string public constant name = "Synthetic Ethereum";
    string public constant symbol = "sETH";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    constructor() {
        wards[msg.sender] = 1;
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "SyntheticEthereum/insufficient-balance");
        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
            require(
                allowance[src][msg.sender] >= wad,
                "SyntheticEthereum/insufficient-allowance"
            );
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        return true;
    }

    function mint(address usr, uint wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
    }

    function burn(address usr, uint wad) external {
        require(balanceOf[usr] >= wad, "SyntheticEthereum/insufficient-balance");
        if (
            usr != msg.sender && allowance[usr][msg.sender] != type(uint256).max
        ) {
            require(
                allowance[usr][msg.sender] >= wad,
                "SyntheticEthereum/insufficient-allowance"
            );
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply = sub(totalSupply, wad);
    }

    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        return true;
    }
}
