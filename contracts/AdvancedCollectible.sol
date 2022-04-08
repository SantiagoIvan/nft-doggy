// SPDX-License-Identifier: MIT
/**
Cada nuevo token creado, tendra como tokenURI a alguna URI correspondiente a las imagenes de perritos
Cada nft sera unico pero bueno la imagen en si va a ser la misma, podria hacer que cada uno sea unico 
teniendo stats, agregando mas metadata, pero bueno al pedo, ahora solo voy a hacer perritos.
 */
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract AdvancedCollectible is ERC721, VRFConsumerBase {
    uint256 public fee;
    bytes32 public keyhash;

    uint256 public tokenCounter;

    mapping(uint256 => Breed) public tokenIdToBreed;
    mapping(bytes32 => address) public requestIdToAddress;
    mapping(bytes32 => string) public requestIdToTokenURI;
    mapping(uint256 => address) public tokenIdToOwner;
    mapping(address => uint256) public ownerToTokenCount;

    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD,
        SHEPHERD
    }

    constructor(
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public ERC721("Doggy", "DOG") VRFConsumerBase(_vrfCoordinator, _link) {
        fee = _fee;
        keyhash = _keyhash;
        tokenCounter = 0;
    }

    event RequestedRandomness(bytes32 indexed requestId, address requester);
    event NFTCreated(uint256 indexed tokenId, Breed breed);

    function createCollectible(string memory _tokenURI)
        public
        returns (uint256)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(msg.sender != address(0));
        bytes32 requestId = requestRandomness(keyhash, fee);

        requestIdToAddress[requestId] = msg.sender;
        requestIdToTokenURI[requestId] = _tokenURI;
        emit RequestedRandomness(requestId, msg.sender);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        /**
        1 - Selecciono a una de las razas de perros
        2 - Mapeo tokenID->raza
        3 - Minteo el nft
        4 - Seteo el tokenUri
        5 - Luego de todo eso actualizo el token counter cuando todo salio correctamente
        
        Un temita que va a haber es que esa funcion que recibe el random, va a ser llamada por el VRF Coordinator
        por lo tanto, a la hora de usar la funcion _safeMint, no puedo usar simplemente msg.sender
        Tengo que guardarme la direccion del creador del nft en algun lado. Recordemos que este proceso
        se inicia llamando a la funcion createCollectible.
        Para asegurarme de relacionar a cada originalSender con su respectivo numero random
        puedo crear un mapa requestIdToAddress
        */

        Breed my_breed = Breed(randomness % 4);
        uint256 newTokenId = tokenCounter;
        string memory _uri = requestIdToTokenURI[requestId];
        _safeMint(requestIdToAddress[requestId], newTokenId);
        // setear el tokenUri aca seria ideal. Necesitaria otro mapa, para mapear el tokenURI con el requestId, ya que el msg.sender es el VRF Coordinator.
        _setTokenURI(newTokenId, _uri);
        address _owner = requestIdToAddress[requestId];
        tokenIdToBreed[newTokenId] = my_breed;
        tokenIdToOwner[newTokenId] = _owner;
        ownerToTokenCount[_owner] += 1;
        tokenCounter++;

        emit NFTCreated(newTokenId, my_breed);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    function getNftsFromUser() public view returns (uint256[] memory) {
        require(msg.sender != address(0), "Error: User null");
        require(ownerToTokenCount[msg.sender] > 0, "Error: user without nfts");

        uint256 _count = ownerToTokenCount[msg.sender];
        uint256[] memory _tokenArray = new uint256[](_count);
        uint256 _current = 0;

        for (uint256 index = 0; index < tokenCounter; index++) {
            if (tokenIdToOwner[index] == msg.sender) {
                _tokenArray[_current] = index;
                _current++;
            }
            if (_current >= ownerToTokenCount[msg.sender]) {
                break;
            }
        }
        return _tokenArray;
    }
}
