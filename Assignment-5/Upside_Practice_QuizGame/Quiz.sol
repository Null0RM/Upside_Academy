// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }
    
    mapping(address => uint256)[] public bets;
    uint public vault_balance;

    // 새롭게 정의한 상태변수들
    mapping(uint256 => Quiz_item) private Quizes;
    mapping(address => bool)[] private isSolved;
    uint256 private quizNum = 1;
    
    constructor () {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public {
        require(msg.sender != address(1), "invalid address");
        quizNum++;
        bets.push();
        Quizes[q.id] = q;
    }

    function getAnswer(uint quizId) public view returns (string memory) {
        Quiz_item memory quiz = Quizes[quizId];
        return quiz.answer;
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory quiz = Quizes[quizId];
        quiz.answer = "";
        return quiz;
    }

    function getQuizNum() public view returns (uint){
        return quizNum;
    }

    function betToPlay(uint quizId) public payable {
        Quiz_item memory quiz = Quizes[quizId];
        require(msg.value >= quiz.min_bet, "low bet");
        require(msg.value <= quiz.max_bet, "high bet");
        bets[quizId - 1][msg.sender] += msg.value;
        isSolved.push();
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        Quiz_item memory quiz = Quizes[quizId];

        if (keccak256(abi.encode(quiz.answer)) == keccak256(abi.encode(ans))) {            
            isSolved[quizId - 1][msg.sender] = true;
            return true;
        }
        else {
            vault_balance += bets[quizId - 1][msg.sender];
            bets[quizId - 1][msg.sender] = 0;
            return false;
        }
    }

    function claim() public {
        for(uint256 i = 1; i < quizNum; i++) {
            if (isSolved[i - 1][msg.sender] == true) {
                isSolved[i - 1][msg.sender] = false;
                (bool suc, ) = payable(msg.sender).call{value: bets[i - 1][msg.sender] * 2}("");
                require(suc, "claim() failed");
                bets[i - 1][msg.sender] = 0;
            }
        }
    }

    receive() external payable {
        vault_balance = payable(address(this)).balance;
    }
}
