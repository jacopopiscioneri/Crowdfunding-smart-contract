// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Fundraise {

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numberOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(address=>uint) public contributors;
    mapping(uint=>Request) public requests;
    uint public numRequests;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public numberOfContributors;


    constructor(uint _target,uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline;
        minimumContribution=10 wei;
        manager=msg.sender;
    }

    modifier onlyManager(){
        require(msg.sender==manager,"You are not authorized");
        _;
    }
    function createRequest(string calldata _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests [numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.numberOfVoters=0;
    }
    function contribution() public payable{
        require(block.timestamp<deadline,"Deadline has passed");
        require(msg.value>=minimumContribution,"Minimum contribution is 10 wei");

        if(contributors[msg.sender]==0){
            numberOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    function getContractbalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target,"you are not eligible for refund");
        require(contributors[msg.sender]>0,"You are not a contributor");
        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    function voteRequest(uint _requestNumber) public{
        require(contributors[msg.sender]>0,"You are not a contrinutor");
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.numberOfVoters++;
    }

    function makePayment(uint _requestNumber) public onlyManager{
        require(raisedAmount>=target,"target is not reached");
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.numberOfVoters>numberOfContributors/2,"Majority does not support the request");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }

}
