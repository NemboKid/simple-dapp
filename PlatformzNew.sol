pragma solidity ^0.5.0;


// @author Filip Sundgren
// @title Platform Z Simple Demo Contract

contract PlatformzNew {


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

    AcceptedSteps public acceptedSteps;

    //mapping(address => uint) public balances;
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


    //@dev Platform Z will become the creator upon contract deployment
    //@param _owner will become the owner and should hence be the contractor
    constructor() public {
        owner = msg.sender;
        isAdmin[owner] = true;
    }

    /**
     *
     * @dev timeContract är antal veckor kontrakt ska pågå. En vecka ligger hårdkodat som unix time.
     * - man måste skicka in pengar i kontraktet här.
     * - developers måste vara tillagda innan start.
     * - varje steg har deadline en fjärdedel av totala tiden. T ex: Om 4 veckor anges kommer varje step
     * ha 1 veckas tid.
     *
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
        return true;
        }

    //require reward to be even and everything to add up to 100%
    //Sätt in alla grejer på en rad likt supplychain
    function addDeveloper(address developer, uint reward) public onlyAdmin onlyBeforeWeight {
        require(contractActive == false, "Cannot add developer after contract has started");
        require(developers[developer].isDeveloper == false, "Is already developer");
        developers[developer] = Developer({developerAddress: developer, weight: reward, acceptedSteps: AcceptedSteps.none, isDeveloper: true, withdrawalCounter: 0});
        developersList.push(developer);
        weightNumberChecker.push(reward);
        checkWeight();
        emit LogDeveloperAdded(developer, reward);
    }

    //objekt kvar i lista även fast borttaget (man nollar bara allt, tror ej man kan ta bort)
    function numberOfDevs() public view returns (uint numberOfDevelopers) {
        return developersList.length;
    }

    /*
    function getDevInfo(uint _devz) public view returns(address) {
        require(isAdmin[msg.sender] || msg.sender == developersList[_devz]);
        return developersList[_devz];
    }*/


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

    /// @dev The Owner can add an additional admin
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

    /*
    function changeDevWeight(address devAddress, uint newWeight) public onlyAdmin {
        require(contractActive == false, "contract must be paused for this function");
        developers[devAddress].weight = newWeight;
        checkWeight();
    }*/


    /**
     * @dev Extend the deadline. Will prolong Step 4, implying one cannot make this call after Step 3.
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

    function pauseContract() public onlyOwner isActive { //make internal
        contractActive = false;
        emit LogPauseContract(true);
    }

    function resumeContract() public onlyOwner {
        require(contractActive == false);
        contractActive = true;
        emit LogResumeContract(false);
    }

    //sätt in nånstans
    function deadlinePassed() internal {
        require(now > contractEndTime);
        selfdestruct(owner);
    }

    function contractKill() public onlyOwner {
        require(contractActive == false, "pause contract before making this call");
        selfdestruct(owner);
    }

    function()external payable {
        require(msg.data.length == 0);
        emit LogDepositReceived(msg.sender);
    }
}
