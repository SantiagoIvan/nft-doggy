from brownie import accounts, network, LinkToken, VRFCoordinatorMock, config, Contract

LOCAL_BLOCKCHAIN_ENVIROMENTS = ["development", "ganache-local"]
FORKED_LOCAL_ENVIROMENTS = ["mainnet-fork"]
OPENSEA_URI = "https://testnets.opensea.io/assets/{}/{}"  # el primero es el contract address y el segundo, el tokenID

contract_to_mock = {
    "link_token": LinkToken,
    "vrf_coordinator": VRFCoordinatorMock,
}

breed_map = {0: "PUG", 1: "SHIBA_INU", 2: "ST_BERNARD", 3: "SHEPHERD"}


def get_account(
    index=None, id=None
):  # para hacerlo mas generico y poder obtener cualquier cuenta por el metodo que sea
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIROMENTS
        or network.show_active() in FORKED_LOCAL_ENVIROMENTS
    ):
        return accounts[0]
    return accounts.add(config["wallets"]["from_key"])


def get_contract(contract_name):

    contract_type = contract_to_mock[contract_name]
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIROMENTS:
        # chequeamos si esta deployado ya.
        # Si no esta deployado los deployamos todos
        if len(contract_type) <= 0:
            deploy_mocks()
        contract = contract_type[-1]
    else:
        contract_address = config["networks"][network.show_active()][contract_name]
        contract = Contract.from_abi(
            contract_type._name, contract_address, contract_type.abi
        )

    return contract


def deploy_mocks():
    account = get_account()

    link_token = LinkToken.deploy({"from": account})

    VRFCoordinatorMock.deploy(link_token.address, {"from": account})

    print("Mocks deployed!")
