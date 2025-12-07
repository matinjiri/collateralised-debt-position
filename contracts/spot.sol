// SPDX-License-Identifier: MIT

/// oracle.sol -- Oracle

pragma solidity ^0.8.13;

interface CoreLike {
    function file(bytes32, uint) external;
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract Oracle {
    // --- Auth ---
    mapping(address => uint) public wards;
    function rely(address guy) external auth {
        wards[guy] = 1;
    }
    function deny(address guy) external auth {
        wards[guy] = 0;
    }
    modifier auth() {
        require(wards[msg.sender] == 1, "Oracle/not-authorized");
        _;
    }

    AggregatorV3Interface public ETHBTCPriceFeed;

    // --- Data ---
    uint256 mat; // Liquidation ratio [ray]

    CoreLike public core; // CDP Engine
    uint256 public par; // ref per sBTC [ray]

    // --- Init ---
    constructor(address vat_, address ETHBTCPriceFeed_) {
        wards[msg.sender] = 1;
        core = CoreLike(vat_);
        par = ONE;
        ETHBTCPriceFeed = AggregatorV3Interface(ETHBTCPriceFeed_);
    }

    // --- Math ---
    uint constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, ONE) / y;
    }

    // --- Administration ---
    function file(bytes32 what, uint data) external auth {
        if (what == "mat") mat = data;
        else revert("Oracle/file-unrecognized-param");
    }

    function peek() public view returns (bytes32, bool) {
        (, int256 answer, , , ) = ETHBTCPriceFeed.latestRoundData();
        uint8 decimals = ETHBTCPriceFeed.decimals();

        require(answer > 0, "Invalid price");
        uint price = uint(answer) * (10**(18 - decimals));  

        return (bytes32(uint256(price)), true);
    }

    // --- Update value ---
    function poke() external {
        (bytes32 val, bool has) = peek();
        uint256 spot = has ? rdiv(rdiv(mul(uint(val), 10 ** 9), par), mat) : 0;
        core.file("spot", spot);
    }
}
