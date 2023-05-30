// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

//The contract Fundraise is defined. it contains a struct requestwhich represent a funding request made by the manager.
contract Fundraise {

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numberOfVoters;
        mapping(address=>bool) voters;
    }
//Declaration of state variables
    mapping(address=>uint) public contributors;//A mapping that stores the contribution amount of each contributor
    mapping(uint=>Request) public requests;//A mapping that stores the funding requests made by the manager
    uint public numRequests;//The total number of funding requests made by the manager
    address public manager;//The address of the contract manager
    uint public minimumContribution;//The minimum amount required for contribution
    uint public deadline;//The deadline (UNIX timestamp) for a contribution
    uint public target;//The target amount to be raised 
    uint public raisedAmount;//The total amount raised so far
    uint public numberOfContributors;//the total number of contributors

//The constructor initializes the contract by setting the target amount, the deadline, manager address and minimum contribution
    constructor(uint _target,uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline;
        minimumContribution=10 wei;
        manager=msg.sender;
    }
//In order to allow only the manager to access and call some of the functions the following modifier is used
    modifier onlyManager(){
        require(msg.sender==manager,"You are not authorized");
        _;   
    }

//With the following function the manager can enter a new request to withdraw part or the entire amount of the funds to proceed with a donation. 
//By entering a new request, the manager has to provide a description of the beneficiary project and the relative amount. 
//The request will be submitted to the vote of the contributors of the smart contract and the payment can be made only in the presence of the majority of votes in favour.

    function createRequest(string calldata _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests [numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.numberOfVoters=0;
    }

//This function allow users to contribute funds to the contract. It requires that the donated amount is >= of the minimum amount allowed for every single donation and that the deadline has not passed (by checking the current timestamp).
    function contribution() public payable{
        require(block.timestamp<deadline,"Deadline has passed");
        require(msg.value>=minimumContribution,"Minimum contribution is 10 wei");

        if(contributors[msg.sender]==0){
            numberOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

//With this function the balance of the contract can be checked, this function is public everyone can check the balance of the contract
    function getContractbalance() public view returns(uint){
        return address(this).balance;
    }

//With the following function a contributor can ask for a refund if the deadline has passed and the total amount of the contract has not reached the target.

    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target,"You are not eligible for refund");
        require(contributors[msg.sender]>0,"You are not a contributor");
        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

//With this function every contributor can vote for the requests done from the manager with the createRequest function, each contributor can vote only one time for every request.
    function voteRequest(uint _requestNumber) public{
        require(contributors[msg.sender]>0,"You are not a contributor");
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.numberOfVoters++;
    }
//once a request has the majority of the votes the payment can be executed with the following function, only the manager can do a transfer from the contract's address
    function makePayment(uint _requestNumber) public onlyManager{
        require(raisedAmount>=target,"target is not reached");
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.numberOfVoters>numberOfContributors/2,"Majority does not support the request");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }

}
