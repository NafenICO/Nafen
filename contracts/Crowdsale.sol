pragma solidity ^0.4.18;

import "./NafenToken.sol";


contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }
}


contract Crowdsale is Ownable, ReentrancyGuard {

  using SafeMath for uint;

  Nafen public tokenContract;
  address tokenContractAddress;

  struct Phase {
  uint start;
  uint period;
  }

  mapping(address => uint) public balances;
  mapping(address => uint) public balancesInCent;
  mapping(address => bool) public whiteList;
  mapping(address => uint) public receivedTokensAmount;

  address public multisig;
  address public teamAddress;

  address public CrowdsaleManager;
  address public oracle;

  uint256 public centHardcap;
  uint256 public centSoftcap;

  uint256 public priceEUR; // wei in one cent

  uint256 public collectedCent;

  uint256 public unwantedBalance = 0;

  Phase[] public phases; // phases of crowdsale

  bool public isUnderHardCap = true;

  function Crowdsale(
  address _multisig,
  address _teamAddress,
  uint _startA,
  uint _periodA,
  uint _startB,
  uint _periodB,
  uint _startC,
  uint _periodC,
  uint _priceEUR) public
  {
    require(_priceEUR!=0 && _priceEUR >0);
    tokenContract = new Nafen();
    tokenContractAddress = tokenContract; // for check in forcedRefund()
    teamAddress = _teamAddress;
    multisig = _multisig;
    phases.push(Phase(_startA, _periodA * 1 days));
    phases.push(Phase(_startB, _periodB * 1 days));
    phases.push(Phase(_startC, _periodC * 1 days));
    centHardcap = 1400000000;
    centSoftcap = 150000000;
    priceEUR = _priceEUR;
  }

  // change phase's start and period
  function shiftPhase(uint phaseIndex, uint newStart, uint newPeriod) public onlyCrowdsaleManagerOrOwner  {
    require(now < phases[phaseIndex].start && now < newStart && newPeriod > 0);
    phases[phaseIndex].start = newStart;
    phases[phaseIndex].period = newPeriod * 1 days;
  }

  function finishCrowdsale() public onlyOwner  {
    require(collectedCent > centSoftcap);
    uint256 collectedEther = this.balance.sub(unwantedBalance);
    bool isSent = multisig.call.gas(3000000).value(collectedEther)();
    require(isSent);
    uint issuedTokenSupply = tokenContract.totalSupply();
    uint restrictedTokens = issuedTokenSupply.mul(5).div(100 - 5);
    tokenContract.mint(teamAddress,restrictedTokens);
    tokenContract.finishMinting();
  }

  function withdrawal() public onlyOwner  {
    require(!isSaleIsON() && collectedCent > centSoftcap);
    uint256 collectedEther = this.balance.sub(unwantedBalance);
    bool isSent = multisig.call.gas(3000000).value(collectedEther)();
    require(isSent);
  }

  function addToWhiteList(address _investor) public onlyCrowdsaleManagerOrOwner  {
    whiteList[_investor] = true;
  }

  function addToBlackList(address _badInvestor) public onlyCrowdsaleManagerOrOwner  {
    whiteList[_badInvestor] = false;
    unwantedBalance = unwantedBalance.add(balances[_badInvestor]);
    collectedCent = collectedCent.sub(balances[_badInvestor].div(priceEUR));
    collectedCent = collectedCent.sub(balancesInCent[_badInvestor]);
  }

  function removeFromBlackList(address _investorAddress) public onlyCrowdsaleManagerOrOwner  {
    whiteList[_investorAddress] = true;
    unwantedBalance = unwantedBalance.sub(balances[_investorAddress]);
    collectedCent = collectedCent.add(balances[_investorAddress].div(priceEUR));
    collectedCent = collectedCent.add(balancesInCent[_investorAddress]);
  }

  function setCrowdsaleManager(address _manager) public onlyOwner  {
    CrowdsaleManager = _manager;
  }


  function manualTransfer(address _to, uint _valueEUR) public onlyCrowdsaleManagerOrOwner   {
    require(isUnderHardCap);
    whiteList[_to] = true;
    uint256 valueCent = _valueEUR * 100;
    //require(collectedCent + valueCent < centHardcap); // ???
    if (collectedCent + valueCent >= centHardcap){
      isUnderHardCap = false;
    }
    uint256 rateCent = getRate();
    uint256 tokensAmount = rateCent.mul(valueCent);
    collectedCent = collectedCent.add(valueCent);
    tokenContract.mint(_to, tokensAmount);
    receivedTokensAmount[_to] = receivedTokensAmount[_to].add(tokensAmount);
    balancesInCent[_to] = balancesInCent[_to].add(valueCent);
  }



  modifier onlyCrowdsaleManagerOrOwner() {
    require(CrowdsaleManager == msg.sender || owner == msg.sender);
    _;
  }

  modifier saleIsOn() {
    require(isSaleIsON());
    _;
  }


  function isSaleIsON()  view public returns(bool ) {

    if ((now > phases[0].start && now < phases[0].start + phases[0].period)
    || (now > phases[1].start && now < phases[1].start + phases[1].period)
    || (now > phases[2].start && now < phases[2].start + phases[2].period))
    {
      return true;
    }
    else return false;
  }

  modifier refundAllowed() {
    require((now > phases[2].start + phases[2].period) && collectedCent < centSoftcap);
    _;
  }

  modifier onlyOracle() {
    require(msg.sender == oracle);
    _;
  }

  function refund() public refundAllowed nonReentrant  {
    uint valueToReturn = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(valueToReturn);
  }

  event requestForManualRefund(address,uint amount);

  function forcedRefund(address _to) public {
    require(msg.sender == tokenContractAddress);
    if (balances[_to] != 0) {
      uint valueToReturn = balances[_to];
      balances[_to] = 0;
      receivedTokensAmount[_to] = 0;
      _to.transfer(valueToReturn);
      unwantedBalance = unwantedBalance.sub(valueToReturn);
    }
    if (balancesInCent[_to] != 0) {
      balancesInCent[_to]  = 0;
      receivedTokensAmount[_to] = 0;
      requestForManualRefund(_to,balancesInCent[_to]);
    }
  }

  function changePriceEUR(uint256 _priceEUR) public onlyOracle  {
    priceEUR = _priceEUR;
  }

  function setOracle(address _oracle) public onlyOwner  {
    oracle = _oracle;
  }

  function getRate() internal view returns(uint256) {
    uint256 _rateCent;
    if (collectedCent < 50000000) {
      _rateCent = 200000000000000000;
    } else if (collectedCent < 140000000) {
      _rateCent = 166666666666666666;
    } else if (collectedCent < 290000000) {
      _rateCent = 133333333333333333;
    } else if (collectedCent < 540000000) {
      _rateCent = 100000000000000000;
    } else if (collectedCent < 900000000) {
      _rateCent = 83000000000000000;
    } else {
      _rateCent = 66666666666666666;
    }
    return _rateCent;
  }

  function mintTokens() nonReentrant saleIsOn public payable {
    require(isUnderHardCap && whiteList[msg.sender]);
    uint256 valueWEI = msg.value;
    uint256 valueCent = valueWEI.div(priceEUR);
    uint256 rateCent = getRate();
    uint256 tokens = rateCent.mul(valueCent);
    if (collectedCent + valueCent > centHardcap)
    {
      isUnderHardCap = false;
      uint256 changeValueCent = collectedCent + valueCent - centHardcap;
      valueCent = valueCent.sub(changeValueCent);
      uint256 oldValueWei = valueWEI;
      valueWEI = valueCent.mul(priceEUR);
      tokens = rateCent.mul(valueCent);
      uint256 change = oldValueWei.sub(valueWEI);
      msg.sender.transfer(change);
    }
    collectedCent = collectedCent.add(valueCent);
    tokenContract.mint(msg.sender, tokens);
    balances[msg.sender] = balances[msg.sender].add(valueWEI);
    receivedTokensAmount[msg.sender] = receivedTokensAmount[msg.sender].add(tokens);
  }

  function () external payable {
    mintTokens();
  }

}

