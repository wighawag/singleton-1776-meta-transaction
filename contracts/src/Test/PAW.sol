pragma solidity 0.6.1;

import "../Interfaces/ERC20.sol";

contract PAW /*is ERC20*/{ // interface seems to require overrides :(

     // --- EIP712 niceties ---
    bytes32 public /*immutable*/ DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    mapping (address => uint256) public nonces;
    string  public constant name     = "Dai Stablecoin";
    string  public constant symbol   = "DAI";
    string  public constant version  = "1";

    ///////////////// EVENTS FOR ERC20 ////////////////
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    ///////////////////////////////////////////////////

    uint256 internal /*immutable*/ _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _supplyClaimed;
    mapping(address => bool) internal _claimed; // TODO optimize it by storing it in the same slot as _balances

    constructor(uint256 supply) public {
        _totalSupply = supply;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            address(this)
        ));
    }

    /// @notice Gets the total number of tokens in existence.
    /// @return the total number of tokens in existence.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // function hasClaimed() TODO

    function _balanceOf(address owner) internal view returns (bool claimed, uint256 balance) {
        balance = _balances[owner];
        if (balance == 0 && !_claimed[owner] && _supplyClaimed < _totalSupply) { // TODO set claimed once balance is set
            claimed = false;
            balance = _totalSupply - _supplyClaimed;
            if (balance > 10000000000000000000) {
                balance = 10000000000000000000;
            }
        } else {
            claimed = true;
        }
    }

    function testBalanceOf(address owner) internal view returns (uint256) {
        uint256 balance = _balances[owner];
        if (balance == 0 && !_claimed[owner] && _supplyClaimed < _totalSupply) { // TODO set claimed once balance is set
            balance = _totalSupply - _supplyClaimed;
            if (balance > 10000000000000000000) {
                balance = 10000000000000000000;
            }
        }
        return balance;
    }

    /// @notice Gets the balance of `owner`.
    /// @param owner The address to query the balance of.
    /// @return The amount owned by `owner`.
    function balanceOf(address owner) public view returns (uint256) {
        (bool _, uint256 balance) = _balanceOf(owner);
        return balance;
    }

    /// @notice gets allowance of `spender` for `owner`'s tokens.
    /// @param owner address whose token is allowed.
    /// @param spender address allowed to transfer.
    /// @return remaining the amount of token `spender` is allowed to transfer on behalf of `owner`.
    function allowance(address owner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[owner][spender];
    }

    /// @notice returns the number of decimals for that token.
    /// @return the number of decimals.
    function decimals() public view returns (uint8) {
        return uint8(18);
    }

    /// @notice Transfer `amount` tokens to `to`.
    /// @param to the recipient address of the tokens transfered.
    /// @param amount the number of tokens transfered.
    /// @return success true if success.
    function transfer(address to, uint256 amount)
        public
        returns (bool success)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfer `amount` tokens from `from` to `to`.
    /// @param from whose token it is transferring from.
    /// @param to the recipient address of the tokens transfered.
    /// @param amount the number of tokens transfered.
    /// @return success true if success.
    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool success)
    {
        if (msg.sender != from) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            if (currentAllowance != (2**256) - 1) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(currentAllowance >= amount, "Not enough funds allowed");
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    // /// @notice burn `amount` tokens.
    // /// @param amount the number of tokens to burn.
    // /// @return true if success.
    // function burn(uint256 amount) external returns (bool) {
    //     _burn(msg.sender, amount);
    //     return true;
    // }

    // /// @notice burn `amount` tokens from `owner`.
    // /// @param owner address whose token is to burn.
    // /// @param amount the number of token to burn.
    // /// @return true if success.
    // function burnFor(address owner, uint256 amount) external returns (bool) {
    //     _burn(owner, amount);
    //     return true;
    // }

    /// @notice approve `spender` to transfer `amount` tokens.
    /// @param spender address to be given rights to transfer.
    /// @param amount the number of tokens allowed.
    /// @return success true if success.
    function approve(address spender, uint256 amount)
        public
        returns (bool success)
    {
        _approveFor(msg.sender, spender, amount);
        return true;
    }

    /// @notice approve `spender` to transfer `amount` tokens from `owner`.
    /// @param owner address whose token is allowed.
    /// @param spender  address to be given rights to transfer.
    /// @param amount the number of tokens allowed.
    /// @return success true if success.
    function approveFor(address owner, address spender, uint256 amount)
        public
        returns (bool success)
    {
        require(
            msg.sender == owner,
            "msg.sender != owner"
        );
        _approveFor(owner, spender, amount);
        return true;
    }


    function _approveFor(address owner, address spender, uint256 amount)
        internal
    {
        require(
            owner != address(0) && spender != address(0),
            "Cannot approve with 0x0"
        );
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Cannot send to 0x0");
        (bool claimed, uint256 currentBalance) = _balanceOf(from);
        require(currentBalance >= amount, "not enough fund");
        if (!claimed) {
            _supplyClaimed += currentBalance;
            _claimed[from] = true; // TODO use bit in _balances to reuse same slot
        }
        _balances[from] = currentBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    // function _mint(address to, uint256 amount) internal {
    //     require(to != address(0), "Cannot mint to 0x0");
    //     require(amount > 0, "cannot mint 0 tokens");
    //     uint256 currentTotalSupply = _totalSupply;
    //     uint256 newTotalSupply = currentTotalSupply + amount;
    //     require(newTotalSupply > currentTotalSupply, "overflow");
    //     _totalSupply = newTotalSupply;
    //     _balances[to] += amount;
    //     emit Transfer(address(0), to, amount);
    // }

    // function _burn(address from, uint256 amount) internal {
    //     require(amount > 0, "cannot burn 0 tokens");
    //     if (msg.sender != from) {
    //         uint256 currentAllowance = _allowances[from][msg.sender];
    //         require(
    //             currentAllowance >= amount,
    //             "Not enough funds allowed"
    //         );
    //         if (currentAllowance != (2**256) - 1) {
    //             // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
    //             _allowances[from][msg.sender] = currentAllowance - amount;
    //         }
    //     }

    //     uint256 currentBalance = balanceOf(from);
    //     require(currentBalance >= amount, "Not enough funds");
    //     _balances[from] = currentBalance - amount;
    //     _totalSupply -= amount;
    //     emit Transfer(from, address(0), amount);
    // }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Dai/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit");
        require(expiry == 0 || now <= expiry, "Dai/permit-expired");
        require(nonce == nonces[holder]++, "Dai/invalid-nonce");
        uint wad = allowed ? uint(-1) : 0;
        _allowances[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}
