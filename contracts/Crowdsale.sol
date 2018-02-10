pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) view returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) view returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  }

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) view returns (uint256 balance) {
    return balances[_owner];
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableBurnableToken is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  address crowdsaleContract;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }

  function burnForRefund() public {
    require(balances[msg.sender] == Crowdsale(owner).receivedTokensAmount(msg.sender) && Crowdsale(owner).whiteList(msg.sender) == false);
    address burner = msg.sender;
    uint256 valueToBurn = balances[burner];
    balances[burner] = 0;
    totalSupply = totalSupply.sub(valueToBurn);
    Burn(burner, valueToBurn);
    Transfer(burner, address(0), valueToBurn);
    Crowdsale(owner).forcedRefund(burner);
  }

}

contract Nafen is MintableBurnableToken {

  string public constant name = "NAFEN";

  string public constant symbol = "NFN";

  uint8 public constant decimals = 18;

  modifier notLocked() {
    require(mintingFinished);
    _;
  }

  function transfer(address _to, uint256 _value) public notLocked returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked returns (bool) {
    return super.transferFrom(from, to, value);
  }


}


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

  uint256 day = 864000; // sec in day

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
  uint _priceEUR)
  {
    require(_priceEUR!=0 && _priceEUR >0);
    tokenContract = new Nafen();
    tokenContractAddress = tokenContract; // for check in forcedRefund()
    teamAddress = _teamAddress;
    multisig = _multisig;
    phases.push(Phase(_startA, _periodA * day));
    phases.push(Phase(_startB, _periodB * day));
    phases.push(Phase(_startC, _periodC * day));
    centHardcap = 1400000000;
    centSoftcap = 150000000;
    priceEUR = _priceEUR;
  }

  // change phase's start and period
  function shiftPhase(uint phaseIndex, uint newStart, uint newPeriod) onlyCrowdsaleManagerOrOwner {
    require(now < phases[phaseIndex].start && now < newStart && newPeriod > 0);
    phases[phaseIndex].start = newStart;
    phases[phaseIndex].period = newPeriod * day;
  }

  function finishCrowdsale() onlyOwner {
    require(collectedCent > centSoftcap);
    uint256 collectedEther = this.balance.sub(unwantedBalance);
    bool isSent = multisig.call.gas(3000000).value(collectedEther)();
    require(isSent);
    uint issuedTokenSupply = tokenContract.totalSupply();
    uint restrictedTokens = issuedTokenSupply.mul(5).div(100 - 5);
    tokenContract.mint(teamAddress,restrictedTokens);
    tokenContract.finishMinting();
  }

  function withdrawal() onlyOwner {
    require(!isSaleIsON() && collectedCent > centSoftcap);
    uint256 collectedEther = this.balance.sub(unwantedBalance);
    bool isSent = multisig.call.gas(3000000).value(collectedEther)();
    require(isSent);
  }

  function addToWhiteList(address _investor) onlyCrowdsaleManagerOrOwner {
    whiteList[_investor] = true;
  }

  function addToBlackList(address _badInvestor) onlyCrowdsaleManagerOrOwner {
    whiteList[_badInvestor] = false;
    unwantedBalance = unwantedBalance.add(balances[_badInvestor]);
    collectedCent = collectedCent.sub(balances[_badInvestor].div(priceEUR));
    collectedCent = collectedCent.sub(balancesInCent[_badInvestor]);
  }

  function removeFromBlackList(address _investorAddress) onlyCrowdsaleManagerOrOwner  {
    whiteList[_investorAddress] = true;
    unwantedBalance = unwantedBalance.sub(balances[_investorAddress]);
    collectedCent = collectedCent.add(balances[_investorAddress].div(priceEUR));
    collectedCent = collectedCent.add(balancesInCent[_investorAddress]);
  }

  function setCrowdsaleManager(address _manager) onlyOwner {
    CrowdsaleManager = _manager;
  }


  function manualTransfer(address _to, uint _valueEUR) onlyCrowdsaleManagerOrOwner  {
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


  function isSaleIsON() view returns(bool ) {

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

  function refund() refundAllowed nonReentrant public {
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

  function changePriceEUR(uint256 _priceEUR) onlyOracle {
    priceEUR = _priceEUR;
  }

  function setOracle(address _oracle) onlyOwner {
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

  function mintTokens() nonReentrant saleIsOn  payable {
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

  function () payable {
    mintTokens();
  }

}

