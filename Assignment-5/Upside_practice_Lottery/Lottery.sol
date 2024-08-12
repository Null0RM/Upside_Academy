// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {

    mapping(uint16 => mapping(address => uint8)) public buyLotteryNum;
    mapping(uint256 => address) public buyRoster;

    uint256 public totalBuyLotteryNum = 0;
    uint256 public numOfWinner = 0;
    uint256 public Deadline;
    uint16 public winningNumber;
    
    bool public isClaim;
    bool public isInit;

    constructor() {
        Deadline = block.timestamp + 24 hours;
        isInit = true;
    }

    /** functions start */
    function initialize() internal {
        Deadline = block.timestamp + 24 hours;
        isInit = true;
        isClaim = false;
        totalBuyLotteryNum = 0;
    }

    function buy(uint16 _lotteryNum) public payable {
        if (isInit == false)
            initialize();
        require(block.timestamp < Deadline, "!!!Times out!!!"); 
        require(msg.value == 0.1 ether, "!!!Insufficient Funds!!!");
        require(buyLotteryNum[_lotteryNum][msg.sender] == 0, "!!!Already Bought!!!");

        buyRoster[totalBuyLotteryNum] = msg.sender;
        buyLotteryNum[_lotteryNum][msg.sender] = 1; // buy 표시
        totalBuyLotteryNum++;
    }

    function draw() public {
        require(isClaim == false, "!!!Not Draw Phase!!!");
        require(block.timestamp >= Deadline, "!!!Not Draw Yet!!!");
        uint16 winNum = winningNumber = uint16(uint256(keccak256(abi.encode(block.timestamp, block.number))));
        for(uint256 i = 0; i < totalBuyLotteryNum; i++) 
        {
            address buyer = buyRoster[i];
            if (buyLotteryNum[winNum][buyer] == 1)
            {
                buyLotteryNum[winNum][buyer] = 2;
                numOfWinner++;
            }
            else
            {
                buyLotteryNum[winNum][buyer] = 0;
            }
        }
        isInit = false;
    }

    function claim() public {
        require(block.timestamp >= Deadline, "!!!Claim Not Yet!!!");
        isClaim = true;
        uint256 prize;

        if (numOfWinner > 0)
            prize = address(this).balance / numOfWinner;

        if (buyLotteryNum[winningNumber][msg.sender] == 2)
        {
            buyLotteryNum[winningNumber][msg.sender] = 0;
            (bool suc, ) = payable(msg.sender).call{value: prize}("");
            require(suc, "!!!claim failed!!!");
        }

        if (numOfWinner > 0)
            numOfWinner--;
    }
}