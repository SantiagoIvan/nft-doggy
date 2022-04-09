// SPDX-License-Identifier: MIT
/**
Cada nuevo token creado, tendra como tokenURI a alguna URI correspondiente a las imagenes de perritos
Cada nft sera unico pero bueno la imagen en si va a ser la misma, podria hacer que cada uno sea unico 
teniendo stats, agregando mas metadata, pero bueno al pedo, ahora solo voy a hacer perritos.
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract AdvancedCollectible is ERC721, VRFConsumerBaseV2 {
    uint32 callbackGasLimit;
    bytes32 keyhash;
    uint64 subscriptionId;
    uint16 requestConfirmations;
    uint32 randomsPerRequest;
    VRFCoordinatorV2Interface COORDINATOR;

    uint256 public lastRandom;
    uint256 public tokenCounter;

    mapping(uint256 => Breed) public tokenIdToBreed;
    mapping(uint256 => address) public requestIdToAddress;
    mapping(uint256 => address) public tokenIdToOwner;
    mapping(address => uint256) public ownerToTokenCount;
    mapping(uint256 => string) private tokenToURI;

    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD,
        SHEPHERD
    }

    constructor(
        address _vrfCoordinator,
        bytes32 _keyhash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _randomsPerRequest
    ) public ERC721("Doggy", "DOG") VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyhash = _keyhash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        randomsPerRequest = _randomsPerRequest;
        tokenCounter = 0;
    }

    event RandomRequested(uint256 indexed requestId, address requester);
    event NFTCreated(uint256 indexed tokenId, Breed breed);

    function createCollectible() public returns (uint256) {
        require(msg.sender != address(0));
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyhash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            randomsPerRequest
        );

        requestIdToAddress[requestId] = msg.sender;
        emit RandomRequested(requestId, msg.sender);
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(randomWords[0] > 0, "Error: no random");
        /**
        1 - Selecciono a una de las razas de perros
        2 - Mapeo tokenID->raza
        3 - Minteo el nft
        4 - Actualizo el token counter 
        */
        lastRandom = randomWords[0];
        Breed my_breed = Breed(lastRandom % 4);
        address _owner = requestIdToAddress[requestId];

        _safeMint(_owner, tokenCounter);
        emit NFTCreated(tokenCounter, my_breed);

        tokenIdToBreed[tokenCounter] = my_breed;
        tokenIdToOwner[tokenCounter] = _owner;
        ownerToTokenCount[_owner] += 1;
        tokenCounter++;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    function getNftsFromUser(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        require(_owner != address(0), "Error: User null");
        require(ownerToTokenCount[_owner] > 0, "Error: user without nfts");

        uint256 _count = ownerToTokenCount[_owner];
        uint256[] memory _tokenArray = new uint256[](_count);
        uint256 _current = 0;

        for (uint256 index = 0; index < tokenCounter; index++) {
            if (tokenIdToOwner[index] == _owner) {
                _tokenArray[_current] = index;
                _current++;
            }
            if (_current >= ownerToTokenCount[_owner]) {
                break;
            }
        }
        return _tokenArray;
    }

    function _setTokenURI(uint256 _tokenId, string memory _uri) internal {
        require(
            _tokenId >= 0 && _tokenId < tokenCounter,
            "Error: null token id"
        );
        tokenToURI[_tokenId] = _uri;
    }

    function getTokenURI(uint256 _tokenId, address _sender)
        public
        view
        returns (string memory)
    {
        require(tokenIdToOwner[_tokenId] == _sender, "Error: Not owner");
        return tokenToURI[_tokenId];
    }
}
