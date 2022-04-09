import logging
from scripts.deploy import deploy
from scripts.utils import breed_map, get_account
from metadata.sample_metadata import metadata_template
from brownie import network
from pathlib import Path
import requests
import json


Log_Format = "%(levelname)s %(asctime)s - %(message)s"

logging.basicConfig(
    filename=f"./metadata/{network.show_active()}/NftToURI.log",
    filemode="w",
    format=Log_Format,
    level=logging.INFO,
)


# voy a crear metadata para cada token creado.
# Yo no voy a saber cual metadata asignarle hasta que se crea el nft, por el tema del random.
# Necesito saber cual perrito es
# Por lo tanto voy a preguntar cuantos tokens hay creados, y voy a iterar por cada uno de ellos
# preguntando de que raza es el perro y asignandole el tokenURI
# Antes de asignarle el tokenURI, voy a tener que subir las fotos de los perros y sus metadatas (2 archivos son, la imagen y el .json)
# a IPFS por ejemplo. Hay otros como FileCoin pero es pago, Pinata tambien, no me deja usar la API sin pagar, hdps :'v

# El formato de la metadata de cada nft lo saco de Opensea. Hay un estandar a seguir para que las distintas
# plataformas puedan leer los datos del nft y mostrarlos


def main():
    logger = logging.getLogger()
    contract = deploy()
    account = get_account()
    create_metadata(contract, account)


def create_metadata(contract, account):
    count_of_collectible = contract.tokenCounter()
    print(f"You have created {count_of_collectible} collectibles!")

    for token_id in range(count_of_collectible):
        if contract.getTokenURI(token_id, account.address).startswith("http"):
            continue  # ya tiene URI asignada

        print("This token", token_id, " has no metadata")
        breed = breed_map[contract.tokenIdToBreed(token_id)]
        metadata_file_name = (
            f"./metadata/{network.show_active()}/{token_id}-{breed}.json"
        )

        if Path(metadata_file_name).exists():
            print(
                f"{metadata_file_name} already exists!"
            )  # el archivo existe entonces se la asigno
            with open(f"./metadata/{network.show_active()}/map.json", "r") as f:
                data = json.load(f)
                uri = data[str(token_id)]
                contract.setTokenURI(token_id, uri, {"from": account})

        else:
            print(f"Creating {metadata_file_name}...")
            nft_metadata = metadata_template
            nft_metadata["name"] = breed
            nft_metadata["description"] = f"An uwuuu {breed}"
            filepath = f"./img/{breed.lower().replace('_', '-')}.png"
            image = upload_to_ipfs(filepath)
            nft_metadata["image"] = image

            # guardamos este objeto nft_metadata en un archivo .json y lo subimos tambien a ipfs
            # esta URI va a ser la que tenemos que guardar en la blockchain.
            with open(metadata_file_name, "w") as f:
                json.dump(nft_metadata, f)
            json_metadata_path = upload_to_ipfs(metadata_file_name)
            tx = contract.setTokenURI(token_id, json_metadata_path, {"from": account})
            tx.wait(1)
            logging.info(f"Token ID: {token_id}, URI: {json_metadata_path}")


# subimos el archivo a nuestro nodo de IPFS. Para eso necesito tener instalado IPFS
# e iniciar el nodo local
# Response format:
# {
#   "Bytes": "<int64>",
#   "Hash": "<string>",
#   "Name": "<string>",
#   "Size": "<string>"
# }
def upload_to_ipfs(filepath):
    with Path(filepath).open("rb") as f:
        image_binary = f.read()
        ipfs_url = "http://127.0.0.1:5001"
        # post
        endpoint = "/api/v0/add"
        response = requests.post(ipfs_url + endpoint, files={"file": image_binary})
        hash = response.json()["Hash"]
        filename = filepath.split("/")[-1]
        image_uri = f"https://ipfs.io/ipfs/{hash}?filename={filename}"
        # formato de request sacado del proyecto anterior
        print("File uri", image_uri)
        return image_uri
