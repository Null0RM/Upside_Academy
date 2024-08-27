// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract DecentralizedNewsPlatform is Initializable, ERC721, Ownable {
    struct Request {
        uint256 requestId;                                  // 고유한 request ID
        address requester;                                  // 요청자의 address
        string description;                                 // 요청된 정보에 대한 description
        uint256 requestTime;                                // 요청된 시간 (timestamp)
        uint256 deadline;                                   // 요청이 만료되는 time (timestamp)
        uint256 fundingGoal;                                // 요청에 필요한 minimum funding 금액 (target fee)
        uint256 totalFunded;                                // 현재까지 모금된 금액
        address[] funders;                                  // 펀딩에 참여한 사람들의 주소 목록
        mapping(address => uint256) fundingContributions;   // 각 펀딩 참여자의 기여 금액
        bool isFunded;                                      // 펀딩 목표가 달성되었는지 여부
        bool isCompleted;                                   // 요청이 완료되었는지 여부 (NFT가 발행되었는지 여부)
        uint256 nftTokenId;                                 // 요청에 따라 발행된 NFT의 ID
    }

    mapping(uint256 => Request) public requests;
    uint256 public nextRequestId;
    IERC20 public daoToken;  // DAO 전용 토큰
    uint256 public votingPeriod;

    function initialize(IERC20 _daoToken, uint256 _votingPeriod) external initializer {
        __ERC721_init("NewsReulDAONFT", "NEWS");
        __Ownable_init();
        daoToken = _daoToken;  // DAO 전용 토큰 설정
        votingPeriod = _votingPeriod;
    }

    function createRequest(string memory _description, uint256 _deadline, uint256 _fundingGoal) public {
        require(_deadline > block.timestamp, "Deadline must be in the future");

        uint256 newRequestId = nextRequestId++;
        Request storage newRequest = requests[newRequestId];
        newRequest.requestId = newRequestId;
        newRequest.requester = msg.sender;
        newRequest.description = _description;
        newRequest.deadline = _deadline;
        newRequest.fundingGoal = _fundingGoal;
        newRequest.totalFunded = 0;
        newRequest.isFunded = false;
        newRequest.isCompleted = false;

        emit RequestCreated(newRequestId, msg.sender, _description);
    }

    function fundRequest(uint256 _requestId, uint256 _amount) public {
        Request storage request = requests[_requestId];
        require(block.timestamp < request.deadline, "Funding deadline has passed");
        require(daoToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        if (request.fundingContributions[msg.sender] == 0) {
            request.funders.push(msg.sender);
        }
        request.fundingContributions[msg.sender] += _amount;
        request.totalFunded += _amount;

        if (request.totalFunded >= request.fundingGoal) {
            request.isFunded = true;
        }

        emit Funded(_requestId, msg.sender, _amount);
    }

    function mintNFT(uint256 _requestId, string memory _uri) public {
        Request storage request = requests[_requestId];
        require(request.isFunded, "Request is not fully funded");
        require(!request.isCompleted, "Request is already completed");
        require(block.timestamp < request.deadline + votingPeriod, "Voting period has ended");

        uint256 nftTokenId = totalSupply() + 1;
        _mint(msg.sender, nftTokenId);
        _setTokenURI(nftTokenId, _uri);
        request.nftTokenId = nftTokenId;
        request.isCompleted = true;

        emit NFTMinted(_requestId, nftTokenId, msg.sender);
    }

    function distributeOwnership(uint256 _requestId) public onlyOwner {
        Request storage request = requests[_requestId];
        require(request.isCompleted, "Request is not completed");
        require(block.timestamp >= request.deadline + votingPeriod, "Voting period has not ended");

        uint256 totalShares = 100;
        uint256 requesterShare = (totalShares * 30) / 100;
        uint256 remainingShares = totalShares - requesterShare;

        _transfer(msg.sender, request.requester, request.nftTokenId);
        for (uint256 i = 0; i < request.funders.length; i++) {
            address funder = request.funders[i];
            uint256 funderContribution = request.fundingContributions[funder];
            uint256 funderShare = (funderContribution * remainingShares) / request.totalFunded;
            _transfer(msg.sender, funder, request.nftTokenId);
        }

        emit VotingCompleted(_requestId, true);
    }

    // 기타 필요한 함수들...
}
