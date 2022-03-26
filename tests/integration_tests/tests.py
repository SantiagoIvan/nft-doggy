from brownie import accounts, config, network, exceptions
from scripts.create_metadata import create_metadata
from scripts.utils import get_account, LOCAL_BLOCKCHAIN_ENVIROMENTS
from scripts.create_dog import create
from scripts.deploy import deploy
import pytest


def test_deployed_successfully():
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIROMENTS:
        pytest.skip()
    contract = deploy()
    assert contract != None


def test_can_create_nft():
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIROMENTS:
        pytest.skip()
    contract = deploy()
    account = get_account()

    prev_id = contract.tokenCounter()
    create(contract, account)
    tokenId = contract.tokenCounter()

    assert tokenId > prev_id


def test_can_create_metadata():
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIROMENTS:
        pytest.skip()
    contract = deploy()
    account = get_account()

    create_metadata(contract, account)

    count = contract.tokenCounter()
    for i in range(count):
        assert contract.tokenURI(i).startswith("http")
