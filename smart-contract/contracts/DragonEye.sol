// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DragonEye is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public NftPerWhitelistLimit = 2;

    bool public paused = false;
    bool public whitelistMintEnabled = true;
    bool public revealed = false;

    //Manually adding my WL address
    address[] public WhitelistAddresses = [
        0x53aE57a6cf0C9Bcb53a8932C97cDaD0a57Ef391d
    ];

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        uint256 supply = totalSupply();
        require(
            (whitelistClaimed[msg.sender] + _mintAmount) <= 2,
            "You already claimed 2 NFTs!"
        );
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        uint256 ownerTokenCount = balanceOf(msg.sender);
        require(ownerTokenCount < NftPerWhitelistLimit);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        whitelistClaimed[msg.sender] += _mintAmount;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < WhitelistAddresses.length; i++) {
            if (WhitelistAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        NftPerWhitelistLimit = _limit;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete WhitelistAddresses;
        WhitelistAddresses = _users;
    }

    function withdraw() public onlyOwner nonReentrant {
        // This will pay HashLips Lab Team 5% of the initial sale.
        // By leaving the following lines as they are you will contribute to the
        // development of tools like this and many others.
        // =============================================================================
        (bool hs, ) = payable(0x146FB9c3b2C13BA88c6945A759EbFa95127486F4).call{
            value: (address(this).balance * 5) / 100
        }("");
        require(hs);
        // =============================================================================

        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
