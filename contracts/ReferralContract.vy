# @version 0.3.7

interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def approve(_spender: address, _value: uint256) -> bool: nonpayable

interface ROUTER:
    def swapExactTokensForTokens(amount: uint256, minRecv: uint256, path: address[2], to: address, deadline: uint256) -> uint256[2]: nonpayable

BONUS_PRECISION: constant(uint256) = 1000
SUSHI_ROUTER: immutable(address)

promotedToken: public(address)
spendingToken: public(address)
referralBonus: public(uint256)
refereeBonus: public(uint256)

bonusAmount: public(uint256)

@external
def __init__(_sushi_router: address, _promotedToken: address, _spendingToken: address, _referralBonus: uint256, _refereeBonus: uint256):
    """
    @notice Contract constructor
    @param _promotedToken Token which referee should buy
    @param _spendingToken Token which referee should spend
    @param referralBonus  Referral incentive to bought amount ratio [0, 1000]
    @param refereeBonus   Referee incentive bonus to bought amount ratio [0, 1000]
    """
    assert referralBonus <= 1000
    assert refereeBonus <= 1000

    self.promotedToken = _promotedToken
    self.spendingToken = _spendingToken
    self.referralBonus = _refereeBonus
    self.refereeBonus = _refereeBonus

    SUSHI_ROUTER = ERC20(_sushi_router)

    ERC20(_spendingToken).approve(_sushi_router, max_value(uint256), default_return_value=True)


@external
def add_bonus(_amount: uint256):
    """
    @notice Contract constructor
    @param _amount Amount of promoted token to add
    """
    self.bonusAmount += _amount
    assert ERC20(self.).transferFrom(msg.sender, self, _amount, default_return_value=True)

    SUSHI_ROUTER = ERC20(_sushi_router)

    ERC20(_spendingToken).approve(_sushi_router, max_value(uint256), default_return_value=True)
