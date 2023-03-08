// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PaymentReciever is Ownable, ReentrancyGuard  {
    address payable public Collector;
    uint256 public brokerage;
    uint256 private _precision = 100;
    address[] public erc20Tokens;

    mapping(address => mapping(address => uint256)) public _netDeposited;

    event PaymentRecieved (
        address indexed from,
        uint256 amount,
        uint256 time,
        address erc20Token
    );

    constructor(address _collector, uint256 _brokerage) {
        Collector = payable(_collector);
        brokerage = _brokerage;
    }

    function updateCollector(address _newCollector) public onlyOwner {
        Collector = payable(_newCollector);
    }

    function findIfErc20Exist(address _token) internal view returns (bool) {
        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            if (erc20Tokens[i] == _token) {
                return true;
            }
        }

        return false;
    }

    function addErc20Token(address _token) public onlyOwner {
        require(!findIfErc20Exist(_token), "Duplicate Entry : ERC20 token already exist");

        erc20Tokens.push(_token);
    }

    function updateBrokerage(uint256 _brokerage) public onlyOwner{
        brokerage = _brokerage;
    }

    function deposit(uint256 _amount, address _erc20Token) external payable nonReentrant {
        require(_amount > 0, "Zero amount : amount should be greater than 0");

        _netDeposited[msg.sender][_erc20Token] += _amount;

        //calculate collector fund
        uint256 CollectorAmount =  (_amount * brokerage) / (100 * _precision);

        //Send collector fund for native token
        if(_erc20Token == address(0)){
            Collector.transfer(CollectorAmount);
        }
        else{
            IERC20 _token  = IERC20(_erc20Token);
            require(_token.allowance(msg.sender, address(this)) >= _amount,"Allowance required : Insuficient Allowance");
            require(_token.transferFrom(msg.sender,address(this),_amount),"Collecter Fund : transfer Failed");
            _token.transfer(Collector, CollectorAmount);
        }

        emit PaymentRecieved(
            msg.sender,
            _amount,
            block.timestamp,
            _erc20Token
        );
    }
}
