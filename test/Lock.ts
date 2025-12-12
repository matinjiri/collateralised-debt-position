import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { Core, GemJoin, WETH9 } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("CDP", function () {

  let core: Core;
  let weth: WETH9;
  let ethJoin: GemJoin;
  let usr: HardhatEthersSigner;

  beforeEach(async function () {
    [usr] = await ethers.getSigners();

    core = await ethers.deployContract("Core");
    weth = await ethers.deployContract("WETH9");
    ethJoin = await ethers.deployContract("GemJoin", [core, ethers.encodeBytes32String("ETH"), weth])
    await core.rely(ethJoin);
  })
  
  it("Join", async function () {
    await weth.deposit({value: ethers.parseEther("1")})
    await weth.approve(ethJoin, ethers.parseEther("1"))
    await ethJoin.join(usr.address, ethers.parseEther("1"))
  });
});
