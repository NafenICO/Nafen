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

contract MintableToken is StandardToken, Ownable {

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

}

contract Nafen is MintableToken {

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

contract PrivatePlacement {

  using SafeMath for uint;

  FiatContract public price = FiatContract(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909); // mainnet 0x8055d0504666e2B6942BeB8D6014c964658Ca591 testnet 0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909

  Nafen tokenContract;

  address multisig;
  address tokenAddress;
  uint256 centHardcap;
  uint256 rateCent; //  one EUR = rate tokens
  uint startA;
  uint periodA;
  uint startB;
  uint periodB;
  uint startC;
  uint periodC;


  function PrivatePlacement(
    address tokenAddress,
    address _multisig,
    uint256 _rate)
  {
    tokenContract = Nafen(tokenAddress);
    multisig = _multisig;
    rateCent = _rate;
  }

  function getCentBalance() constant returns (uint256) {
    return this.balance.div(price.EUR(0));
  }


  modifier isUnderHardCap() {
    require(getCentBalance() <= centHardcap);
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


  function mintTokens() isUnderHardCap payable {
    uint256 valueWEI = msg.value;
    uint256 priceEUR = price.EUR(0);
    uint256 valueCent = valueWEI.div(priceEUR);
    uint256 centBalance = getCentBalance();
    if (centBalance < 50000000) {
      rateCent = 200000000000000000;
    } else if (centBalance < 90000000) {
      rateCent = 166666666666666666;
    } else if (centBalance < 150000000) {
      rateCent = 133333333333333333;
    } else if (centBalance < 250000000) {
      rateCent = 100000000000000000;
    } else if (centBalance < 360000000) {
      rateCent = 83000000000000000;
    } else if (centBalance < 500000000) {
      rateCent = 66666666666666667;
    }
    uint256 tokens = rateCent.mul(valueCent).div(1 ether);
    if (centBalance > centHardcap)
    {
      uint256 changeValueCent = centBalance - centHardcap;
      tokens -= rateCent.mul(changeValueCent).div(1 ether);
      uint256 change = msg.value - valueCent.mul(priceEUR);
      bool isSent = msg.sender.call.gas(3000000).value(change)();
      require(isSent);
    }

    //balances[msg.sender] = balances[msg.sender].add(valueWEI);
  }

  function () payable {
    mintTokens();
  }

}


