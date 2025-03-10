// Rock-Paper-Scissors-Lizard-Spock Game
contract RPS is CommitReveal, TimeUnit {
    uint public constant TIMEOUT = 5 minutes;
    uint public rewardPool;
    uint public numPlayers;
    uint public numRevealed;

    enum Choice { Rock, Paper, Scissors, Lizard, Spock }

    mapping(address => Choice) private choices;
    mapping(address => bool) public hasRevealed;
    address[2] public players;

    modifier onlyPlayers() {
        require(msg.sender == players[0] || msg.sender == players[1], "Not a player");
        _;
    }

    function joinGame(bytes32 commitHash) external payable {
        require(numPlayers < 2, "Game full");
        require(msg.value == 1 ether, "Must send 1 ether");

        players[numPlayers] = msg.sender;
        rewardPool += msg.value;
        commit(commitHash);
        numPlayers++;
        if (numPlayers == 2) {
            startTime = block.timestamp;
        }
    }

    function revealChoice(Choice choice, bytes32 randomString) external onlyPlayers {
        require(numPlayers == 2, "Game not full");
        require(block.timestamp <= startTime + TIMEOUT, "Reveal period expired");
        require(!hasRevealed[msg.sender], "Already revealed");
        require(getHash(keccak256(abi.encodePacked(choice, randomString))) == commits[msg.sender].commit, "Invalid reveal");
        
        choices[msg.sender] = choice;
        hasRevealed[msg.sender] = true;
        numRevealed++;
        
        if (numRevealed == 2) {
            _determineWinner();
        }
    }

    function _determineWinner() private {
        Choice choice1 = choices[players[0]];
        Choice choice2 = choices[players[1]];
        address payable player1 = payable(players[0]);
        address payable player2 = payable(players[1]);

        bool player1Wins = (
            (choice1 == Choice.Rock && (choice2 == Choice.Scissors || choice2 == Choice.Lizard)) ||
            (choice1 == Choice.Paper && (choice2 == Choice.Rock || choice2 == Choice.Spock)) ||
            (choice1 == Choice.Scissors && (choice2 == Choice.Paper || choice2 == Choice.Lizard)) ||
            (choice1 == Choice.Lizard && (choice2 == Choice.Paper || choice2 == Choice.Spock)) ||
            (choice1 == Choice.Spock && (choice2 == Choice.Rock || choice2 == Choice.Scissors))
        );
        
        bool player2Wins = (
            (choice2 == Choice.Rock && (choice1 == Choice.Scissors || choice1 == Choice.Lizard)) ||
            (choice2 == Choice.Paper && (choice1 == Choice.Rock || choice1 == Choice.Spock)) ||
            (choice2 == Choice.Scissors && (choice1 == Choice.Paper || choice1 == Choice.Lizard)) ||
            (choice2 == Choice.Lizard && (choice1 == Choice.Paper || choice1 == Choice.Spock)) ||
            (choice2 == Choice.Spock && (choice1 == Choice.Rock || choice1 == Choice.Scissors))
        );

        if (player1Wins) {
            player1.transfer(rewardPool);
        } else if (player2Wins) {
            player2.transfer(rewardPool);
        } else {
            player1.transfer(rewardPool / 2);
            player2.transfer(rewardPool / 2);
        }
        _resetGame();
    }

    function forceEndGame() external {
        require(block.timestamp > startTime + TIMEOUT, "Timeout not reached yet");
        require(numRevealed < 2, "Game already resolved");

        for (uint i = 0; i < numPlayers; i++) {
            if (hasRevealed[players[i]]) {
                payable(players[i]).transfer(rewardPool / numPlayers);
            }
        }
        _resetGame();
    }

    function _resetGame() private {
        delete players;
        numPlayers = 0;
        numRevealed = 0;
        rewardPool = 0;
        startTime = 0;
    }
}
