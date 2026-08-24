// SPDX-License-Identifier: MIT
pragma solidity =0.8.36;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "NOT_OWNER");

        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZERO_OWNER");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);
    }
}

contract BITCOS_PRIME is IERC20, Ownable {
    string private constant _NAME = "Bitcos Prime";
    string private constant _SYMBOL = "BOS";

    uint8 private constant _DECIMALS = 18;

    uint256 private constant _MAX_SUPPLY = 2_100_000 * 10 ** 18;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    address public stakingContract;

    address public liquidityPair;

    mapping(address => bool) public excludedFromBuyRestriction;

    event StakingContractSet(address staking);

    event LiquidityPairSet(address pair);

    event ExcludedUpdated(address wallet, bool status);

    constructor() {
        _balances[msg.sender] = _MAX_SUPPLY;

        excludedFromBuyRestriction[msg.sender] = true;

        emit Transfer(address(0), msg.sender, _MAX_SUPPLY);
    }

    function name() external pure returns (string memory) {
        return _NAME;
    }

    function symbol() external pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() external pure override returns (uint256) {
        return _MAX_SUPPLY;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 allowed = _allowances[sender][msg.sender];

        require(allowed >= amount, "ALLOWANCE");

        unchecked {
            _allowances[sender][msg.sender] = allowed - amount;
        }

        _transfer(sender, recipient, amount);

        emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);

        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ZERO_SENDER");

        require(recipient != address(0), "ZERO_RECEIVER");

        if (sender == liquidityPair) {
            if (!excludedFromBuyRestriction[recipient]) {
                require(recipient == stakingContract, "ONLY_STAKING_BUY");
            }
        }

        require(_balances[sender] >= amount, "BALANCE_LOW");

        unchecked {
            _balances[sender] -= amount;

            _balances[recipient] += amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    function setLiquidityPair(address _pair) external {
        require(msg.sender == owner() || msg.sender == stakingContract, "NOT_AUTHORIZED");

        liquidityPair = _pair;

        emit LiquidityPairSet(_pair);
    }

    function setStakingContract(address _staking) external {
        require(msg.sender == owner() || msg.sender == stakingContract, "NOT_AUTHORIZED");

        stakingContract = _staking;

        excludedFromBuyRestriction[_staking] = true;

        emit StakingContractSet(_staking);
    }

    function setExcluded(address wallet, bool status) external {
        require(msg.sender == owner() || msg.sender == stakingContract, "NOT_AUTHORIZED");

        excludedFromBuyRestriction[wallet] = status;

        emit ExcludedUpdated(wallet, status);
    }

    function tokenDetails() external pure returns (string memory, string memory, uint8, uint256) {
        return (_NAME, _SYMBOL, _DECIMALS, _MAX_SUPPLY);
    }
}
