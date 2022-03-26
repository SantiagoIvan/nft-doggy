from scripts.utils import get_account, OPENSEA_URI
from scripts.deploy import deploy


def create(contract, account):
    tx = contract.createCollectible("", {"from": account})
    tx.wait(15)
    print(
        "NFT Created! you can see it at ",
        OPENSEA_URI.format(contract.address, contract.tokenCounter() - 1),
    )


def main():
    account = get_account()
    contract = deploy()
    create(contract, account)
