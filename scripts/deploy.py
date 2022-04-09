from brownie import AdvancedCollectible, config, network
from scripts.utils import get_account


def deploy():
    account = get_account()
    contract = (
        AdvancedCollectible[-1]
        if AdvancedCollectible
        else AdvancedCollectible.deploy(
            config["networks"][network.show_active()]["vrf_coordinator_v2"],
            config["networks"][network.show_active()]["keyhash"],
            config["networks"][network.show_active()]["subscription_id"],
            config["networks"][network.show_active()]["callback_gas_limit"],
            config["networks"][network.show_active()]["request_confirmations"],
            config["networks"][network.show_active()]["randoms_per_request"],
            {"from": account},
            publish_source=config["networks"][network.show_active()]["verify"],
        )
    )

    return contract


def main():
    deploy()
