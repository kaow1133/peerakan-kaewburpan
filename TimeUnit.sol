// TimeUnit Contract
contract TimeUnit {
    uint256 public startTime;

    function setStartTime() public {
        startTime = block.timestamp;
    }

    function elapsedSeconds() public view returns (uint256) {
        return block.timestamp - startTime;
    }

    function elapsedMinutes() public view returns (uint256) {
        return (block.timestamp - startTime) / 1 minutes;
    }
}
