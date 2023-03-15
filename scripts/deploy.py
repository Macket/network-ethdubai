from brownie import accounts, network
from brownie import UniswapV2Factory, UniswapV2Pair, UniswapV2Router02, ERC20Mock, ReferralContract

SHORT_NAME = "crvUSD"
FULL_NAME = "Curve.Fi USD Stablecoin"


def main():
    mainnet = network.show_active() == 'mainnet'
    if mainnet:
        raise NotImplementedError("Mainnet not implemented yet")

    txparams = {'from': accounts[0]}
    admin = accounts[0]
    liquidity_provider = accounts[1]
    referral = accounts[2]
    referee = accounts[3]

    factory = UniswapV2Factory.deploy(admin, txparams)
    fakeWETH = ERC20Mock.deploy("Fake WETH", "fakeWETH", 18, txparams)
    router = UniswapV2Router02.deploy(factory, fakeWETH, txparams)

    macs = ERC20Mock.deploy("Not a scam", "macs", 18, txparams)
    crvUSD = ERC20Mock.deploy("Curve Stablecoin!!!", "crvUSD", 18, txparams)

    # --- ADD LIQUIDITY ---

    macs._mint_for_testing(liquidity_provider, 10**6 * 10**18, txparams)
    crvUSD._mint_for_testing(liquidity_provider, 10**6 * 10**18, txparams)
    macs.approve(router, 2**256 - 1, {"from": liquidity_provider})
    crvUSD.approve(router, 2**256 - 1, {"from": liquidity_provider})
    router.addLiquidity(macs, crvUSD, 1000 * 10**18, 1000 * 10**18, 1000 * 10**18, 1000 * 10**18, liquidity_provider, 16788776556560, {"from": liquidity_provider})
    pool = UniswapV2Pair.at(factory.getPair(macs, crvUSD))

    # --- PROVIDE INCENTIVES ---
    referral_contract = ReferralContract.deploy(router, macs, crvUSD, 50, 50, txparams)
    macs.approve(referral_contract, 10**4 * 10**18, {"from": liquidity_provider})
    referral_contract.add_bonus(10**4 * 10**18, {"from": liquidity_provider})

    # --- BUY ---
    crvUSD._mint_for_testing(referee, 100 * 10**18, txparams)
    crvUSD.approve(referral_contract, 2**256 - 1, {"from": referee})
    referral_contract.ape(100 * 10**18, 0, 2**256 - 1, referral, {"from": referee})

    print('========================')
    print('Factory:     ', factory.address)
    print('Router:      ', router.address)
    print('Macs:        ', macs.address)
    print('Stablecoin:  ', crvUSD.address)
    print('Pool:        ', pool.address)
    # print('Controller:  ', controller.address)
