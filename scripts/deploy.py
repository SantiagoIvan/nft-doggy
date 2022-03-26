from brownie import AdvancedCollectible, config, network
from scripts.utils import get_account


def deploy():
    account = get_account()
    contract = (
        AdvancedCollectible[-1]
        if AdvancedCollectible
        else AdvancedCollectible.deploy(
            config["networks"][network.show_active()]["vrf_coordinator"],
            config["networks"][network.show_active()]["link_token"],
            config["networks"][network.show_active()]["fee"],
            config["networks"][network.show_active()]["keyhash"],
            {"from": account},
        )
    )
    return contract


def main():
    deploy()
