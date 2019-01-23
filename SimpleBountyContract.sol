pragma solidity ^0.5.0;


// @author Filip Sundgren
// @title Simple Demo Contract

contract SimpleBountyContract {


    /**
     * Storage
     */
    address payable public owner;
    uint public contractEndTime;
    uint public depositAmount;
    uint public weightGuard;
    uint oneWeek = 604800;
    uint public stepCount;
    bool public contractActive;
    uint public timeStep;
    bool public hasStarted;

    AcceptedSteps public acceptedSteps;

    mapping(address => Developer) public developers;
    mapping (address => bool) public isAdmin;

    address[] public developersList;
    uint[] public weightNumberChecker;
    address[] public admins;


    /**
     * Structs
     */
    struct Developer {
        address developerAddress;
        uint weight;
        AcceptedSteps acceptedSteps;
        bool isDeveloper;
        uint withdrawalCounter;
    }


    /**
     * Enums
     * @param
     * @dev
     * @return
     *
     */
    enum AcceptedSteps {
       none,
       first,
       second,
       third,
       fourth
    }


    /**
     * Events
     */
    event LogNoneAcceptedStep(string none);
    event LogFirstAcceptedStep(string first);
    event LogSecondAcceptedStep(string second);

    event LogDeveloperStatus(address devAddress,
                            uint weight,
                            uint acceptedSteps,
                            bool isDeveloper,
                            uint withdrawals);

    event LogDeadlineExtended(uint newDeadline);
    event LogContractEndsAt(uint unixTimeOfContract);

    event LogDeveloperAdded(address developerAddressAdded, uint developerRewardWeight);
    event LogAdminAdded(address adminAddress);

    event LogPauseContract(bool contractPaused);
    event LogResumeContract(bool contractActive);

    event LogStepCount(uint stepCount);

    event LogWithdrawal(uint amountWithdrawn);

    event LogDepositReceived (address whoSent);


    /**
     * Modifiers
     */

    modifier onlyAdmin {
        require((isAdmin[msg.sender] == true) || msg.sender == owner, "Only admin or owner can perfom this");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can perfom this");
        _;
    }

    modifier inState(AcceptedSteps _steps) {
        require(acceptedSteps == _steps, "Invalid state");
        _;
    }

    modifier onlyDeveloper(address _address) {
        require(developers[_address].isDeveloper = true, "Only for devs");
        _;
    }

    modifier isActive {
        require(contractActive == true, "Contract must be active");
        _;
    }

    modifier onlyBefore (uint _time) {
        require(now <= _time, "Contract deadline was passed. All remaining funds returned to contract creator");
        deadlinePassed();
        _;
    }

    modifier onlyAfter (uint _time) {
        require(now >= _time, "Deadline passed");
        _;
    }

    /*modifier checkMaxWeight (uint _weightNumberChecker) {
        require(weightNumberChecker >= 0 && weightNumberChecker <= 100, "% Must be between 0-100");
        _;
    }*/


    modifier allRewardGiven {
        _;
        uint s = 0;
        for(uint i=0; i < weightNumberChecker.length; i++){
            s += weightNumberChecker[i];
            require(s == 100, "total reward must add up to 100");
        }
    }

    modifier onlyBeforeWeight {
        _;
        uint s = 0;
        for(uint i=0; i < weightNumberChecker.length; i++){
            s += weightNumberChecker[i];
            require(s <= 100, "Cannot exceed 100% reward for developers");
        }
    }


    //@dev Deployer's address will become owner
    constructor() public {
        owner = msg.sender;
        isAdmin[owner] = true;
    }

    /**
     *
     * @dev need to transfer value at this step, which will be the value of your project.
     * @dev Developers need to be inserted before start, and the total weight (reward) for devs must be 100% of contract's amount.
     * @param timeContract is total weeks that's hardcoded as unix seconds on line 17.
     * @return success true
     *
     */
    function startWork(uint timeContract) public payable onlyAdmin returns (bool success) {
        checkWeight();
        require(developersList.length > 0, "You must add at least one developer before starting");
        require(timeContract <= 52, "52 weeks is the maximum contract time");
        require(msg.value % 2 == 0, "Even value required.");
        require(msg.value != 0, "Must send money");
        require(weightGuard == 100, "weight must be 100%");
        depositAmount = msg.value;
        require(contractActive == false, "contract already started");
        contractActive = true;
        contractEndTime = (timeContract * oneWeek) + now;
        timeStep = (timeContract * oneWeek) / 4;
        emit LogContractEndsAt(contractEndTime);
        hasStarted = true;
        return true;
        }


    // @dev require reward to be even and everything to add up to 100%
    function addDeveloper(address developer, uint reward) public onlyAdmin onlyBeforeWeight {
        require(contractActive == false, "Cannot add developer after contract has started");
        require(developers[developer].isDeveloper == false, "Is already developer");
        developers[developer] = Developer({developerAddress: developer, weight: reward, acceptedSteps: AcceptedSteps.none, isDeveloper: true, withdrawalCounter: 0});
        developersList.push(developer);
        weightNumberChecker.push(reward);
        checkWeight();
        emit LogDeveloperAdded(developer, reward);
    }


    function numberOfDevs() public view returns (uint numberOfDevelopers) {
        return developersList.length;
    }

    
    /**
     * @dev Owner accepts step when necessary and stepCount will increase by one (stepCount +1).
     */
    function stepAccept() public onlyAdmin isActive {
        require(stepCount < 5);
        if (stepCount == 0) {
            require(now <= (timeStep + now), "First step deadline has passed");
            stepCount ++;
            emit LogStepCount(stepCount);
            for(uint8 i = 0; i < developersList.length; i++) {
                require(developers[developersList[i]].acceptedSteps == AcceptedSteps.none);
                require(developersList[i] != address(0));
                developers[developersList[i]].acceptedSteps = AcceptedSteps.first;
            }
        } else if (stepCount == 1) {
            require(now <= (timeStep * 2 + now), "Second step deadline has passed");
            stepCount ++;
            emit LogStepCount(stepCount);
                for(uint8 i = 0; i < developersList.length; i++) {
                    require(developers[developersList[i]].acceptedSteps == AcceptedSteps.first);
                    require(developersList[i] != address(0));
                    developers[developersList[i]].acceptedSteps = AcceptedSteps.second;
                }
        } else if (stepCount == 2) {
            require(now <= (timeStep * 3 + now), "Third step deadline has passed");
            stepCount ++;
            emit LogStepCount(stepCount);
                for(uint8 i = 0; i < developersList.length; i++) {
                    require(developers[developersList[i]].acceptedSteps == AcceptedSteps.second);
                    require(developersList[i] != address(0));
                    developers[developersList[i]].acceptedSteps = AcceptedSteps.third;
                }
        } else if (stepCount == 3) {
            require(now <= (timeStep * 4 + now), "Fourth step deadline has passed");
            stepCount ++;
            for(uint8 i = 0; i < developersList.length; i++) {
                require(developers[developersList[i]].acceptedSteps == AcceptedSteps.third);
                require(developersList[i] != address(0));
                developers[developersList[i]].acceptedSteps = AcceptedSteps.fourth;
            }
        }
    }
    
    /**
     * @dev Developers can here withdraw their earnings. For each accepted step, they can take out their weight (decided by the
     *      owner) / 4 (since there are 4 hard coded steps).
     */

   function withdrawal() public onlyDeveloper(msg.sender) isActive {
       uint weight = developers[msg.sender].weight;
       if (stepCount == 1) {
            require(developers[msg.sender].withdrawalCounter == 0);
            msg.sender.transfer(((depositAmount * weight) / 100) / 4);
            developers[msg.sender].withdrawalCounter ++;
            emit LogWithdrawal(((depositAmount * weight) / 100) / 4);
        } else if (stepCount == 2) {
            require(developers[msg.sender].withdrawalCounter <= 1);
            msg.sender.transfer(((depositAmount * weight) / 100) / 4);
            developers[msg.sender].withdrawalCounter ++;
            emit LogWithdrawal(((depositAmount * weight) / 100) / 4);
        } else if (stepCount == 3) {
            require(developers[msg.sender].withdrawalCounter <= 2);
            msg.sender.transfer(((depositAmount * weight) / 100) / 4);
            developers[msg.sender].withdrawalCounter ++;
            emit LogWithdrawal(((depositAmount * weight) / 100) / 4);
        } else if (stepCount == 4) {
            require(developers[msg.sender].withdrawalCounter <= 3);
            msg.sender.transfer(((depositAmount * weight) / 100) / 4);
            developers[msg.sender].withdrawalCounter ++;
            emit LogWithdrawal(((depositAmount * weight) / 100) / 4);
        }
    }


    /// @dev The Owner can add an additional address to have admin status. Cannot be developer.
    function addAdmin(address _admin) public onlyAdmin {
        require(isAdmin[_admin] == false);
        require(developers[_admin].isDeveloper == false);
        isAdmin[_admin] = true;
        admins.push(_admin);
        emit LogAdminAdded(_admin);
    }


    /**
     * Admin tools
     */

     /**
     * @dev Checks current weight of project. Needs to add up to 100 before contract can start.
     */
    function checkWeight() internal {
        uint k = 0;
        for(uint i=0; i < weightNumberChecker.length; i++){
            k += weightNumberChecker[i];
        }
        weightGuard = k;
    }


    function checkBalance() public view onlyAdmin returns(uint contractBalance) {
        return address(this).balance;
    }


    /**
     * @dev Remove single dev from list. Can only be done if contract hasn't yet started, or is paused.
     * @param Address of developer, and it's place in developersList need to be the same. Used as a control mechanism.
     */
    function removeSingleDev(address devAddress, uint devInList) public onlyAdmin {
        require(developersList[devInList] == devAddress, "addresses doesn't match");
        delete developersList[devInList];
        developersList.length --;
        delete weightNumberChecker[devInList];
        delete developers[devAddress];
        checkWeight();
    }


    function removeAdmin(address adminAddress) public {
        require(isAdmin[adminAddress] = true);
        require(adminAddress != owner);
        isAdmin[adminAddress] = false;
        for (uint i = 0; i< admins.length - 2; i++)
            admins[i] = admins[admins.length - 1];
    }


    // @dev Decided to abandon this function due to many security issues. Would be nice feature, but a bit unnecessary when you
    //      also can delete single devs and insert them again.
    /*
    function changeDevWeight(address devAddress, uint newWeight) public onlyAdmin {
        require(contractActive == false, "contract must be paused for this function");
        developers[devAddress].weight = newWeight;
        checkWeight();
    }*/


    /**
     * @dev Extend the deadline. Will prolong whole contract and can't be made after Step 3. 
     * @dev Unnecessary function for such a simple contract?
     * @param newTime is the number of weeks the new time will be extended with.
     **/
    function extendDeadline(uint newTime) public onlyAdmin {
        require(stepCount <= 3, "Cannot change contract time after third step");
        require(newTime * oneWeek + contractEndTime <= now + 31449600, "Deadline can't be longer than a year");
        uint newDeadline = (newTime * oneWeek) + contractEndTime;
        contractEndTime = newDeadline;
        timeStep = contractEndTime / 4;
        emit LogDeadlineExtended(newDeadline);
    }
    
    
    /**
     * @dev Security switch with both On and Off functions. Have some concerns for resumeContract() and its efficiency, both having contractActive(bool) and hasStarted(bool). 
     * @dev Unnecessary function for such a simple contract?
     * @param newTime is the number of weeks the new time will be extended with.
     **/
    function pauseContract() public onlyOwner isActive { //make internal
        contractActive = false;
        emit LogPauseContract(true);
    }

    function resumeContract() public onlyOwner {
        require(contractActive == false && hasStarted == false);
        contractActive = true;
        emit LogResumeContract(false);
    }

    // This one needs to find a place and is not used today. Control mechanism, but where would it fit best? Want a nice finish for my contract.
    function deadlinePassed() internal {
        require(now > contractEndTime);
        selfdestruct(owner);
    }

    /**
     * @dev If Owner wants to cancel the whole job and return his funds. Dangerous to combine with require(contractActive == false)?
     * @param newTime is the number of weeks the new time will be extended with.
     **/
    function contractKill() public onlyOwner {
        require(contractActive == false, "pause contract before making this call");
        selfdestruct(owner);
    }

    // Fallback function. 
    function()external payable {
        require(msg.data.length == 0);
        emit LogDepositReceived(msg.sender);
    }
}
