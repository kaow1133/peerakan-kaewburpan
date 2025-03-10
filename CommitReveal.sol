// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// CommitReveal Contract
contract CommitReveal {
    uint8 public constant MAX_RANDOM = 100;

    struct Commit {
        bytes32 commit;
        uint64 blockNumber;
        bool revealed;
    }

    mapping(address => Commit) public commits;
    
    event CommitHash(address indexed sender, bytes32 dataHash, uint64 blockNumber);
    event RevealHash(address indexed sender, bytes32 revealHash, uint random);

    function commit(bytes32 dataHash) external {
        require(commits[msg.sender].commit == bytes32(0), "Already committed");
        commits[msg.sender] = Commit(dataHash, uint64(block.number), false);
        emit CommitHash(msg.sender, dataHash, uint64(block.number));
    }

    function reveal(bytes32 revealHash) external {
        Commit storage userCommit = commits[msg.sender];
        require(!userCommit.revealed, "Already revealed");
        require(getHash(revealHash) == userCommit.commit, "Invalid reveal");
        require(block.number > userCommit.blockNumber, "Reveal in the same block not allowed");
        require(block.number <= userCommit.blockNumber + 250, "Reveal too late");
        
        userCommit.revealed = true;
        bytes32 blockHash = blockhash(userCommit.blockNumber);
        uint random = uint(keccak256(abi.encodePacked(blockHash, revealHash))) % MAX_RANDOM;
        
        emit RevealHash(msg.sender, revealHash, random);
    }

    function getHash(bytes32 data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }
}
