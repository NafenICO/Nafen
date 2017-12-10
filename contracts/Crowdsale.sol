pragma solidity ^0.4.15;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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
  mapping (address => bool) public crowdsaleContracts;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier onlyCrowdsaleContract() {
    require(crowdsaleContracts[msg.sender]);
    _;
  }

  function addCrowdsaleContract(address _crowdsaleContract) onlyOwner {
    crowdsaleContracts[_crowdsaleContract] = true;
  }

  function deleteCrowdsaleContract(address _crowdsaleContract) onlyOwner {
    require(crowdsaleContracts[_crowdsaleContract]);
    delete crowdsaleContracts[_crowdsaleContract];
  }
  function mint(address _to, uint256 _amount) onlyCrowdsaleContract canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(this, _to, _amount);
    return true;
  }

  function finishMinting() onlyCrowdsaleContract returns (bool) {
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
  }

}

contract Nafen is MintableBurnableToken {

  string public constant name = "Nafen";

  string public constant symbol = "NFN";

  uint32 public constant decimals = 18;

}

contract FiatContract {
  function ETH(uint _id) constant returns (uint256);
  function USD(uint _id) constant returns (uint256);
  function EUR(uint _id) constant returns (uint256);
  function GBP(uint _id) constant returns (uint256);
  function updatedAt(uint _id) constant returns (uint);
}


contract Crowdsale is Ownable {
  
  using SafeMath for uint;

  Nafen tokenContract;

  mapping(address => uint) public balances;
  mapping(address => bool) public whiteList;

  address multisig;
  address tokenAddress;
  address CrowdsaleManager;
  uint256 public centHardcap;
  uint256 public centSoftcap;
  uint256 startA;
  uint256 periodA;
  uint256 startB;
  uint256 periodB;
  uint256 startC;
  uint256 periodC;
  uint256 day = 864000; // sec in day
  uint256 priceEUR; // wei in one cent
  uint256 centBalance;

  bool isUnderHardCap = true;

  function Crowdsale(
  address tokenAddress,
  address _multisig,
  uint _startA,
  uint _periodA,
  uint _startB,
  uint _periodB,
  uint _startC,
  uint _periodC,
  uint _priceEUR)
  {
    tokenContract = Nafen(tokenAddress);
    multisig = _multisig;
    startA = _startA;
    periodA = _periodA * day;
    startB = _startB;
    periodB = _periodB * day;
    startC= _startC;
    periodC = _periodC * day;
    centHardcap = 1400000000;
    centSoftcap = 150000000;
    priceEUR = _priceEUR;
  }

  function finishCrowdsale() onlyOwner {
    uint256 curBalance = getCentBalance();
    require(curBalance > centSoftcap);
    bool isSent = multisig.call.gas(3000000).value(this.balance)();
    require(isSent);
    tokenContract.finishMinting();
  }

  function addToWhiteList(address _investor) onlyCrowdsaleManagerOrOwner {
    whiteList[_investor] = true;
  }

  function setCrowdsaleManager(address _manager) onlyOwner {
    CrowdsaleManager = _manager;
  }

  function getCentBalance() constant returns (uint256) {
    return this.balance.div(priceEUR);
  }

  function handleSale(address _to, uint _valueEUR) onlyCrowdsaleManagerOrOwner  {
    uint256 valueCent = _valueEUR * 100;
    uint256 rateCent = getRate();
    uint256 tokensAmount = rateCent.mul(valueCent);
    centBalance += valueCent;
    tokenContract.mint(_to, tokensAmount);
  }


  modifier onlyCrowdsaleManagerOrOwner() {
    require(CrowdsaleManager == msg.sender || owner == msg.sender);
    _;
  }
 
  modifier saleIsOn() {
    require(
    (now > startA && now < startA + periodA)
    || (now > startB && now < startB + periodB)
    || (now > startC && now < startC + periodC)
    );
    _;
  }

  
  function isSaleIsON() constant returns(bool ){

    if ((now > startA && now < startA + periodA)
    || (now > startB && now < startB + periodB)
    || (now > startC && now < startC + periodC))
    {
      return true;
    }
    else return false;

  }

  modifier refundAllowed() {
    uint256 curBalance = getCentBalance();
    require((now > startC + periodC) && curBalance < centSoftcap);
    _;
  }

  function refund() refundAllowed public {
    uint valueToReturn = balances[msg.sender];
    balances[msg.sender] = 0;
    bool isSent = msg.sender.call.gas(3000000).value(valueToReturn)();
    require(isSent);
  }

  function getRate() constant returns(uint256){
    uint256 _rateCent;
    if (centBalance < 50000000) {
      _rateCent = 200000000000000000;
    } else if (centBalance < 140000000) {
      _rateCent = 166666666666666666;
    } else if (centBalance < 290000000) {
      _rateCent = 133333333333333333;
    } else if (centBalance < 540000000) {
      _rateCent = 100000000000000000;
    } else if (centBalance < 900000000) {
      _rateCent = 83000000000000000;
    } else {
      _rateCent = 66666666666666666;
    }
    return _rateCent;
  }

  function mintTokens() saleIsOn payable {
    require(isUnderHardCap && whiteList[msg.sender]);
    uint256 valueWEI = msg.value;
    uint256 valueCent = valueWEI.div(priceEUR);
    uint256 rateCent = getRate();
    uint256 tokens = rateCent.mul(valueCent);
    if (centBalance + valueCent > centHardcap)
    {
      isUnderHardCap = false;
      uint256 changeValueCent = centBalance + valueCent - centHardcap;
      valueCent -= changeValueCent;
      valueWEI = valueCent.mul(priceEUR);
      tokens = rateCent.mul(valueCent);
      uint256 change = msg.value - valueWEI;
      bool isSent = msg.sender.call.gas(3000000).value(change)();
      require(isSent);
    }
    tokenContract.mint(msg.sender, tokens);
    balances[msg.sender] = balances[msg.sender].add(valueWEI);
  }

  function () payable {
    mintTokens();
  }
}
