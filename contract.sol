pragma solidity ^0.5.1;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20 {
    function transfer(address receiver, uint amount) public;
    function balanceOf(address owner) public  returns (uint);
}

contract Ownable {
  address public buyer;
  address public seller;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event SellerTransferred(address indexed previousSeller, address indexed newSeller);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    buyer = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyBuyer() {
    require(msg.sender == buyer);
    _;
  }

  modifier onlySeller() {
    require(msg.sender == seller);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyBuyer public {
    require(newOwner != address(0));
    emit OwnershipTransferred(buyer, newOwner);
    buyer = newOwner;
  }

  function transferWork(address newSeller) onlySeller public {
    require(newSeller != address(0));
    emit SellerTransferred(seller, newSeller);
    seller = newSeller;
  }

}

contract EscrowDeal is Ownable {
    using SafeMath for uint256;

    ERC20 token;
    address public admin;

    bool workAccepted = false;
    bool workDone = false;
    bool dispute = false;

    event approvedByBuyer(address indexed from, bool value);
    event approvedBySeller(address indexed from, bool value);
    event disputeEvent(bool value);

    constructor (address _token, address _seller, address _admin) public {
        admin = _admin;
        seller = _seller;
        token = ERC20(_token);
    }

    function buyerApprove() public onlyBuyer {
        workAccepted = true;
        checkConsensus();
    }

    function sellerApprove() public onlySeller {
        workDone = true;
        checkConsensus();
    }

    function checkConsensus() internal {
        require(workDone);
        require(workAccepted);
        releaseFunds();
    }

    function releaseFunds() internal {
        require(!dispute);
        transferTokens(seller);
    }

    function transferTokens(address receiver) internal {
        address self = address(this);
        uint256 balance = token.balanceOf(self);
        token.transfer(receiver, balance);
    }

    function rejectWork() public onlyBuyer {
        workAccepted = false;
    }

    function disputeContract() public onlyBuyer {
        dispute = true;
        emit disputeEvent(dispute);
    }

    function resolveDispute(bool approval) public {
        require(msg.sender == admin);
        if(approval) transferTokens(buyer);
        else transferTokens(seller);
    }
}
