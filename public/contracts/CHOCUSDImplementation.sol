/*
* DISCLAIMER
* The source code and any related material provided on this platform are intended for testing purposes only. 
* Please read our full disclaimer before using this code or any related materials in any capacity: 
* https://github.com/CertiKProject/unstablecoin/blob/main/public/disclaimer.md.
*/

pragma solidity ^0.4.24;
pragma experimental "v0.5.0";

import "./zeppelin/SafeMath.sol";

/**
 * @title CHOCUSDImplementation
 * @dev this contract is a Pausable ERC20 token with Burn and Mint
 * controlled by a central SupplyController. By implementing CHOCUSDImplementation
 * this contract also includes external methods for setting
 * a new implementation contract for the Proxy.
 * NOTE: The storage defined here will actually be held in the Proxy
 * contract and all calls to this contract should be made through
 * the proxy, including admin actions done as owner or supplyController.
 * Any call to transfer against this contract should fail
 * with insufficient funds since no tokens will be issued there.
 */
contract CHOCUSDImplementation {
    /**
     * MATH
     */

    using SafeMath for uint256;

    /**
     * DATA
     */

    // INITIALIZATION DATA
    bool private initialized;

    // ERC20 BASIC DATA
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;
    string public constant name = "Chocolate USD"; // solium-disable-line
    string public constant symbol = "CHOCUSD"; // solium-disable-line uppercase
    uint8 public constant decimals = 6; // solium-disable-line uppercase

    // ERC20 DATA
    mapping(address => mapping(address => uint256)) internal allowed;

    // OWNER DATA PART 1
    address public owner;

    // PAUSABILITY DATA
    bool public paused;

    // ASSET PROTECTION DATA
    address public assetProtectionRole;
    mapping(address => bool) internal frozen;

    // SUPPLY CONTROL DATA
    address public supplyController;

    // OWNER DATA PART 2
    address public proposedOwner;

    /**
     * EVENTS
     */

    // ERC20 BASIC EVENTS
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC20 EVENTS
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // OWNABLE EVENTS
    event OwnershipTransferProposed(
        address indexed currentOwner,
        address indexed proposedOwner
    );
    event OwnershipTransferDisregarded(address indexed oldProposedOwner);
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    // PAUSABLE EVENTS
    event Pause();
    event Unpause();

    // ASSET PROTECTION EVENTS
    event AddressFrozen(address indexed addr);
    event AddressUnfrozen(address indexed addr);
    event FrozenAddressWiped(address indexed addr);
    event AssetProtectionRoleSet(
        address indexed oldAssetProtectionRole,
        address indexed newAssetProtectionRole
    );

    // SUPPLY CONTROL EVENTS
    event SupplyIncreased(address indexed to, uint256 value);
    event SupplyDecreased(address indexed from, uint256 value);
    event SupplyControllerSet(
        address indexed oldSupplyController,
        address indexed newSupplyController
    );

    /**
     * FUNCTIONALITY
     */

    // INITIALIZATION FUNCTIONALITY

    /**
     * @dev sets 0 initials tokens, the owner, and the supplyController.
     * this serves as the constructor for the proxy but compiles to the
     * memory model of the Implementation contract.
     */
    function initialize() public {
        require(
            !initialized,
            "MANDATORY VERIFICATION REQUIRED: The proxy has already been initialized, verify the owner and supply controller addresses."
        );
        owner = msg.sender;
        assetProtectionRole = address(0);
        totalSupply_ = 0;
        supplyController = msg.sender;
        initialized = true;
    }

    /**
     * The constructor is used here to ensure that the implementation
     * contract is initialized. An uncontrolled implementation
     * contract might lead to misleading state
     * for users who accidentally interact with it.
     */
    constructor() public {
        initialize();
        pause();
    }

    // ERC20 BASIC FUNCTIONALITY

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Transfer token to a specified address from msg.sender
     * Note: the use of Safemath ensures that _value is nonnegative.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        require(_to != address(0), "cannot transfer to address zero");
        require(!frozen[_to] && !frozen[msg.sender], "address frozen");
        require(_value <= balances[msg.sender], "insufficient funds");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _addr The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _addr) public view returns (uint256) {
        return balances[_addr];
    }

    // ERC20 FUNCTIONALITY

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        require(_to != address(0), "cannot transfer to address zero");
        require(
            !frozen[_to] && !frozen[_from] && !frozen[msg.sender],
            "address frozen"
        );
        require(_value <= balances[_from], "insufficient funds");
        require(_value <= allowed[_from][msg.sender], "insufficient allowance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(
        address _spender,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "address frozen");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * To increment allowed value is better to use this function to avoid 2 calls (and wait until the first transaction
     * is mined) instead of approve.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint _addedValue
    ) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "address frozen");
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(
            _addedValue
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * To decrement allowed value is better to use this function to avoid 2 calls (and wait until the first transaction
     * is mined) instead of approve.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    ) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "address frozen");
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // OWNER FUNCTIONALITY

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    /**
     * @dev Allows the current owner to begin transferring control of the contract to a proposedOwner
     * @param _proposedOwner The address to transfer ownership to.
     */
    function proposeOwner(address _proposedOwner) public onlyOwner {
        require(
            _proposedOwner != address(0),
            "cannot transfer ownership to address zero"
        );
        require(msg.sender != _proposedOwner, "caller already is owner");
        proposedOwner = _proposedOwner;
        emit OwnershipTransferProposed(owner, proposedOwner);
    }
    /**
     * @dev Allows the current owner or proposed owner to cancel transferring control of the contract to a proposedOwner
     */
    function disregardProposeOwner() public {
        require(
            msg.sender == proposedOwner || msg.sender == owner,
            "only proposedOwner or owner"
        );
        require(
            proposedOwner != address(0),
            "can only disregard a proposed owner that was previously set"
        );
        address _oldProposedOwner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferDisregarded(_oldProposedOwner);
    }
    /**
     * @dev Allows the proposed owner to complete transferring control of the contract to the proposedOwner.
     */
    function claimOwnership() public {
        require(msg.sender == proposedOwner, "onlyProposedOwner");
        address _oldOwner = owner;
        owner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferred(_oldOwner, owner);
    }

    /**
     * @dev Reclaim all CHOCUSD at the contract address.
     * This sends the CHOCUSD tokens that this contract add holding to the owner.
     * Note: this is not affected by freeze constraints.
     */
    function reclaimCHOCUSD() external onlyOwner {
        uint256 _balance = balances[this];
        balances[this] = 0;
        balances[owner] = balances[owner].add(_balance);
        emit Transfer(this, owner, _balance);
    }

    // PAUSABILITY FUNCTIONALITY

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "whenNotPaused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner {
        require(!paused, "already paused");
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner {
        require(paused, "already unpaused");
        paused = false;
        emit Unpause();
    }

    // ASSET PROTECTION FUNCTIONALITY

    /**
     * @dev Sets a new asset protection role address.
     * @param _newAssetProtectionRole The new address allowed to freeze/unfreeze addresses and seize their tokens.
     */
    function setAssetProtectionRole(address _newAssetProtectionRole) public {
        require(
            msg.sender == assetProtectionRole || msg.sender == owner,
            "only assetProtectionRole or Owner"
        );
        require(
            assetProtectionRole != _newAssetProtectionRole,
            "new address is same as a current one"
        );
        emit AssetProtectionRoleSet(
            assetProtectionRole,
            _newAssetProtectionRole
        );
        assetProtectionRole = _newAssetProtectionRole;
    }

    modifier onlyAssetProtectionRole() {
        require(msg.sender == assetProtectionRole, "onlyAssetProtectionRole");
        _;
    }

    /**
     * @dev Freezes an address balance from being transferred.
     * @param _addr The new address to freeze.
     */
    function freeze(address _addr) public onlyAssetProtectionRole {
        require(!frozen[_addr], "address already frozen");
        frozen[_addr] = true;
        emit AddressFrozen(_addr);
    }

    /**
     * @dev Unfreezes an address balance allowing transfer.
     * @param _addr The new address to unfreeze.
     */
    function unfreeze(address _addr) public onlyAssetProtectionRole {
        require(frozen[_addr], "address already unfrozen");
        frozen[_addr] = false;
        emit AddressUnfrozen(_addr);
    }

    /**
     * @dev Wipes the balance of a frozen address, and burns the tokens.
     * @param _addr The new frozen address to wipe.
     */
    function wipeFrozenAddress(address _addr) public onlyAssetProtectionRole {
        require(frozen[_addr], "address is not frozen");
        uint256 _balance = balances[_addr];
        balances[_addr] = 0;
        totalSupply_ = totalSupply_.sub(_balance);
        emit FrozenAddressWiped(_addr);
        emit SupplyDecreased(_addr, _balance);
        emit Transfer(_addr, address(0), _balance);
    }

    /**
     * @dev Gets whether the address is currently frozen.
     * @param _addr The address to check if frozen.
     * @return A bool representing whether the given address is frozen.
     */
    function isFrozen(address _addr) public view returns (bool) {
        return frozen[_addr];
    }

    // SUPPLY CONTROL FUNCTIONALITY

    /**
     * @dev Sets a new supply controller address.
     * @param _newSupplyController The address allowed to burn/mint tokens to control supply.
     */
    function setSupplyController(address _newSupplyController) public {
        require(
            msg.sender == supplyController || msg.sender == owner,
            "only SupplyController or Owner"
        );
        require(
            _newSupplyController != address(0),
            "cannot set supply controller to address zero"
        );
        require(
            supplyController != _newSupplyController,
            "new address is same as a current one"
        );
        emit SupplyControllerSet(supplyController, _newSupplyController);
        supplyController = _newSupplyController;
    }

    modifier onlySupplyController() {
        require(msg.sender == supplyController, "onlySupplyController");
        _;
    }

    /**
     * @dev Increases the total supply by minting the specified number of tokens to the supply controller account.
     * @param _value The number of tokens to add.
     * @return A boolean that indicates if the operation was successful.
     */
    function increaseSupply(
        uint256 _value
    ) public returns (bool success) {
        totalSupply_ = totalSupply_.add(_value);
        balances[supplyController] = balances[supplyController].add(_value);
        emit SupplyIncreased(supplyController, _value);
        emit Transfer(address(0), supplyController, _value);
        return true;
    }

    /**
     * @dev Decreases the total supply by burning the specified number of tokens from the supply controller account.
     * @param _value The number of tokens to remove.
     * @return A boolean that indicates if the operation was successful.
     */
    function decreaseSupply(
        uint256 _value
    ) public onlySupplyController returns (bool success) {
        require(_value <= balances[supplyController], "not enough supply");
        balances[supplyController] = balances[supplyController].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit SupplyDecreased(supplyController, _value);
        emit Transfer(supplyController, address(0), _value);
        return true;
    }
}
