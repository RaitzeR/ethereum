pragma solidity ^0.4.10;

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
/**
 * @title DistributionMiddleware contract enables divvying of incoming eth amongst the stakeholders.
 */
contract DistributionMiddleware {

	/*
    * @title Simple eth Distribution Middleware Contract
    * @author Ville Virta
    */

    //State Variables
	mapping(address => StakeHolder) stakeHolders;
	address[] addressIndices;
	address owner;

	//Events
	event Deposit(address _sender, uint amount);
	event Divvy(address _sender);

	//Function Modifiers
	modifier isOwner(){
		require(msg.sender == owner);
		_;
	}
	modifier isStakeHolder() {
	    require(stakeHolders[msg.sender].isEnabled);
	    _;
	}

	//Structs
	struct StakeHolder {
		uint lifeTimeEarnings;
		string name;
		bool isEnabled;
	}

	//Constructor
	function DistributionMiddleware () public {
		owner = msg.sender;
	}

	/** @dev Adds a stakeholder 
	* @param address _address
	* @param string _name Chosen name of the stakeholder
	 */
	function addStakeHolder(address _address, string _name) public isOwner {
	    require(!stakeHolders[_address].isEnabled);
		addressIndices.push(_address);
		stakeHolders[_address].name = _name;
		stakeHolders[_address].isEnabled = true;
	}

	/** @dev Divvies up all the balance inside the contract with current stakeholders.
	* @notice This will also increase the lifetime earnings of the stakeholders
	 */
	function divvyUp() public isStakeHolder {
		require(this.balance > 0);
		uint divvy = SafeMath.div(this.balance,addressIndices.length);
	    uint totalShared = divvy * addressIndices.length;
	    for(uint i = 0; i < addressIndices.length; i++) {
	    	addressIndices[i].send(divvy);
	        stakeHolders[addressIndices[i]].lifeTimeEarnings += divvy;
	    } 
	    if(this.balance > 0) {
	    	uint randomWinner = getRandomNumber(addressIndices.length);
	    	addressIndices[randomWinner].send(this.balance - totalShared);
	        stakeHolders[addressIndices[randomWinner]].lifeTimeEarnings += this.balance - totalShared;
	    }
	    Divvy(msg.sender);
	}

	/** @dev Default function. Add divvyUp() inside here to divvy all the incoming eth when they arrive 
	 */
	function() public payable {
		Deposit(msg.sender, msg.value);
	}


	/** @dev Outputs a "random" number between 0 and max 
	* @param uint max Max number in the range
	* @return uint randomNumber
	 */
	function getRandomNumber(uint max) private constant returns(uint randomNumber) {
	    return uint(keccak256(block.timestamp))%max;
	}

	/* Getters */

	/** @dev Outputs the count of how many stakeholders there are 
	* @return uint stakeHolderCount
	 */
	function getStakeHolderCount() public constant isStakeHolder returns(uint stakeHolderCount) {
		return addressIndices.length;
	}

	/** @dev Outputs stakeholder information by name 
	* @param string _name The name of the stakeholder
	* @return uint lifeTimeEarnings
	* @return string name
	* @return address _address
	 */
	function getStakeHolderWithName(string _name) public constant returns(uint lifeTimeEarnings,string name,address _address) {
	    for(uint i = 0; i < addressIndices.length; i++) {
	        if(keccak256(stakeHolders[addressIndices[i]].name) == keccak256(_name)) {
	            return (stakeHolders[addressIndices[i]].lifeTimeEarnings, stakeHolders[addressIndices[i]].name, addressIndices[i]);
	        }
	    } 
	}
	
	/** @dev Outputs nth stakeholder information 
	* @param uint nth
	* @return uint lifeTimeEarnings
	* @return string name
	* @return address _address
	 */
	function getStakeHolderAtPosition(uint nth) public constant isStakeHolder returns(uint lifeTimeEarnings,string name,address _address) {
	    require(i < addressIndices.length);
	    return(stakeHolders[addressIndices[nth]].lifeTimeEarnings, stakeHolders[addressIndices[nth]].name, addressIndices[nth]);
	}

	/** @dev Outputs stakeholder information by address 
	* @param address _address
	* @return uint lifeTimeEarnings
	* @return string name
	* @return address _address
	 */
	function getStakeHolderWithAddress(address _address) public constant returns(uint lifeTimeEarnings,string name,address _address) {
	    for(uint i = 0; i < addressIndices.length; i++) {
            if(addressIndices[i] == _address) {
                return (stakeHolders[addressIndices[i]].lifeTimeEarnings, stakeHolders[addressIndices[i]].name, addressIndices[i]);
	        }
	    } 
	}

	/** @dev Outputs the sum of lifetime earnings of stakeholders
	* @return uint sumOfLifeTimeEarnings
	* @return uint contractBalance
	 */
	function getBalances() public constant isStakeHolder returns(uint sumOfLifeTimeEarnings, uint contractBalance) {
	    uint totalStakeHolderBalance = 0;
	    for(uint i = 0; i < addressIndices.length; i++) {
	        totalStakeHolderBalance = totalStakeHolderBalance + stakeHolders[addressIndices[i]].lifeTimeEarnings;
	    }
	    return(totalStakeHolderBalance, this.balance);
	}
}
