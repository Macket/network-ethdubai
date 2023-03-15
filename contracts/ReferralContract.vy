# @version 0.3.7

interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def approve(_spender: address, _value: uint256) -> bool: nonpayable

interface ROUTER:
    def swapExactTokensForTokens(amount: uint256, minRecv: uint256, path: DynArray[address, 2], to: address, deadline: uint256) -> DynArray[uint256, 2]: nonpayable

struct Lock:
    amount: uint256
    unlock_time: uint256

BONUS_PRECISION: constant(uint256) = 1000
LOCK_TIME: constant(uint256) = 4 * 7 * 86400  # 4 weeks

SUSHI_ROUTER: immutable(ROUTER)

promoted_token: public(address)
spending_token: public(address)
referral_bonus: public(uint256)
referee_bonus: public(uint256)

bonus_amount: public(uint256)
locks: public(HashMap[address, Lock])
referral_earnings: public(HashMap[address, uint256])


@external
def __init__(_sushi_router: address, _promoted_token: address, _spending_token: address, _referral_bonus: uint256, _referee_bonus: uint256):
    """
    @notice Contract constructor
    @param _promoted_token Token which referee should buy
    @param _spending_token Token which referee should spend
    @param _referral_bonus  Referral incentive to bought amount ratio [0, 1000]
    @param _referee_bonus   Referee incentive bonus to bought amount ratio [0, 1000]
    """
    assert _referral_bonus <= 100  # dev: bonus <= 10%
    assert _referee_bonus <= 100  # dev: bonus <= 10%

    self.promoted_token = _promoted_token
    self.spending_token = _spending_token
    self.referral_bonus = _referee_bonus
    self.referee_bonus = _referee_bonus

    SUSHI_ROUTER = ERC20(_sushi_router)

    ERC20(_spending_token).approve(_sushi_router, max_value(uint256), default_return_value=True)


@external
def add_bonus(_amount: uint256):
    """
    @notice Add tokens for incentives
    @param _amount Amount of promoted token to add
    """
    self.bonus_amount += _amount
    assert ERC20(self.promoted_token).transferFrom(msg.sender, self, _amount, default_return_value=True)


@external
def ape(_amount: uint256, _minRecv: uint256, _deadline: uint256, _referral: address):
    """
    @notice Buy promoted tokens
    @param _amount Amount of promoted token to buy
    """
    assert _amount > 0 # dev: _amount < 0
    _promoted_token: address = self.promoted_token
    _spending_token: address = self.spending_token

    assert ERC20(_spending_token).transferFrom(msg.sender, self, _amount, default_return_value=True)
    _recv: DynArray[uint256, 2] = SUSHI_ROUTER.swapExactTokensForTokens(_amount, _minRecv, [_spending_token, _promoted_token], self, _deadline)

    _referee_bonus: uint256 = _recv[1] * self.referee_bonus / BONUS_PRECISION
    _referral_bonus: uint256 = _recv[1] * self.referral_bonus / BONUS_PRECISION
    self.bonus_amount -= _referee_bonus + _referral_bonus
    self.locks[msg.sender].amount += _recv[1] + _referee_bonus
    self.locks[msg.sender].unlock_time = block.timestamp + LOCK_TIME

    self.referral_earnings[_referral] += _referral_bonus
    ERC20(self.promoted_token).transfer(_referral, _referral_bonus)


@external
def withdraw_unlocked():
    _unlock_time: uint256 = self.locks[msg.sender].unlock_time
    assert _unlock_time > 0 # dev: no funds
    assert _unlock_time < block.timestamp # dev: still locked

    ERC20(self.promoted_token).transfer(msg.sender, self.locks[msg.sender].amount)
