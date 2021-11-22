// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAddressRegistry {
    function marketplace() external view returns (address);

    function tokenRegistry() external view returns (address);
}

interface IMarketplace {
    function validateItemSold(
        address,
        uint256,
        address,
        address
    ) external;
}

interface ITokenRegistry {
    function enabled(address) external returns (bool);
}

contract BundleMarketplace is
    Ownable,
    ReentrancyGuard
{

    using SafeERC20 for IERC20;
    // using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Events for the contract
    event ItemListed(
        address indexed owner,
        string bundleID,
        address payToken,
        uint256 price,
        uint256 startingTime
    );
    event ItemSold(
        address indexed seller,
        address indexed buyer,
        string bundleID,
        address payToken,
        int256 unitPrice,
        uint256 price
    );
    event ItemUpdated(
        address indexed owner,
        string bundleID,
        address[] nft,
        uint256[] tokenId,
        uint256[] quantity,
        address payToken,
        uint256 newPrice
    );
    event ItemCanceled(address indexed owner, string bundleID);
    event OfferCreated(
        address indexed creator,
        string bundleID,
        address payToken,
        uint256 price,
        uint256 deadline
    );
    event OfferCanceled(address indexed creator, string bundleID);
    event UpdatePlatformFee(uint256 platformFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);

    /// @notice Structure for Bundle Item Listing
    struct Listing {
        address[] nfts;
        uint256[] tokenIds;
        uint256[] quantities;
        address payToken;
        uint256 price;
        uint256 startingTime;
    }

    /// @notice Structure for bundle offer
    struct Offer {
        IERC20 payToken;
        uint256 price;
        uint256 deadline;
    }

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Owner -> Bundle ID -> Bundle Listing item
    mapping(address => mapping(bytes32 => Listing)) public listings;

    /// @notice Bundle ID -> owner
    mapping(bytes32 => address) public owners;

    /// @notice nft address -> bundleId -> item bundle 
    mapping(address => mapping(uint256 => EnumerableSet.Bytes32Set)) bundleIdsPerItem;

    /// @notice Bundle ID -> nft address -> nft id
    mapping(bytes32 => mapping(address => mapping(uint256 => uint256))) nftIndexes;

    /// @notice Bundle ID -> keccak256(abi.encodePacked(_bundleID))
    mapping(bytes32 => string) bundleIds;

    /// @notice Bundle ID -> Offerer -> Offer
    mapping(bytes32 => mapping(address => Offer)) public offers;

    /// @notice Platform fee
    uint256 public platformFee;

    /// @notice Platform fee receipient
    address payable public treasuryAddress;

    /// @notice Address registry
    IAddressRegistry public addressRegistry;

    //can only be called by the marketplace contracts
    modifier onlyContract() {
        require(
            addressRegistry.marketplace() == _msgSender(),
            "sender must be marketplace"
        );
        _;
    }

    //constructor sets the platform fee and treasury address
    constructor(address payable _treasuryAddress, uint16 _platformFee) {
        treasuryAddress = _treasuryAddress;
        platformFee = _platformFee;
    }

    /// @notice Method for get NFT bundle listing
    /// @param _owner Owner address
    /// @param _bundleID Bundle ID
    function getListing(address _owner, string memory _bundleID)
        external
        view
        returns (
            address[] memory nfts,
            uint256[] memory tokenIds,
            uint256[] memory quantities,
            uint256 price,
            uint256 startingTime
        )
    {
        bytes32 bundleID = _getBundleID(_bundleID);
        nfts = listings[_owner][bundleID].nfts;
        tokenIds = listings[_owner][bundleID].tokenIds;
        quantities = listings[_owner][bundleID].quantities;
        price = listings[_owner][bundleID].price;
        startingTime = listings[_owner][bundleID].startingTime;
    }

    /// @notice Method for listing NFT bundle
    /// @param _bundleID Bundle ID
    /// @param _nftAddresses Addresses of NFT contract
    /// @param _tokenIds Token IDs of NFT
    /// @param _quantities token amounts to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
    /// @param _price sale price for bundle
    /// @param _startingTime scheduling for a future sale
    function listItem(
        string memory _bundleID,
        address[] calldata _nftAddresses,
        uint256[] calldata _tokenIds,
        uint256[] calldata _quantities,
        address _payToken,
        uint256 _price,
        uint256 _startingTime
    ) external {
        bytes32 bundleID = _getBundleID(_bundleID);
        bundleIds[bundleID] = _bundleID;

        //ensures that the number of items are in equal length so its valid
        require(
            _nftAddresses.length == _tokenIds.length &&
                _tokenIds.length == _quantities.length,
            "invalid data"
        );

        //checks if bundle is already listed
        require(
            owners[bundleID] == address(0) ||
                (owners[bundleID] == _msgSender() &&
                    listings[_msgSender()][bundleID].price == 0),
            "already listed"
        );

        //pay token validity
        address tokenRegistry = addressRegistry.tokenRegistry();
        require(
            _payToken == address(0) ||
                (tokenRegistry != address(0) &&
                    ITokenRegistry(tokenRegistry).enabled(_payToken)),
            "invalid pay token"
        );

        //remove existing listing created from sender with the same bundle id
        Listing storage listing = listings[_msgSender()][bundleID];
        delete listing.nfts;
        delete listing.tokenIds;
        delete listing.quantities;

        //checks for the validity of the nft contract
        for (uint256 i; i < _nftAddresses.length; i++) {

            //check if nft is owned and approved
            if (_supportsInterface(_nftAddresses[i], INTERFACE_ID_ERC721)) {
                IERC721 nft = IERC721(_nftAddresses[i]);
                _check721Owning(_nftAddresses[i], _tokenIds[i], _msgSender());
                require(
                    nft.isApprovedForAll(_msgSender(), address(this)),
                    "item not approved"
                );

                listing.quantities.push(uint256(1));
            } else if (
                _supportsInterface(_nftAddresses[i], INTERFACE_ID_ERC1155)
            ) {
                IERC1155 nft = IERC1155(_nftAddresses[i]);
                _check1155Owning(
                    _nftAddresses[i],
                    _tokenIds[i],
                    _quantities[i],
                    _msgSender()
                );
                require(
                    nft.isApprovedForAll(_msgSender(), address(this)),
                    "item not approved"
                );

                listing.quantities.push(_quantities[i]);
            } else {
                revert("invalid nft address");
            }

            //adds the new details to the structs
            address _nft = _nftAddresses[i];
            listing.nfts.push(_nft);
            listing.tokenIds.push(_tokenIds[i]);
            bundleIdsPerItem[_nft][_tokenIds[i]].add(bundleID);
            nftIndexes[bundleID][_nft][_tokenIds[i]] = i;
        }

        //updates pay token, price, startingtime to the listing detail
        listing.payToken = _payToken;
        listing.price = _price;
        listing.startingTime = _startingTime;

        //sets bundle owner
        owners[bundleID] = _msgSender();

        emit ItemListed(
            _msgSender(),
            _bundleID,
            _payToken,
            _price,
            _startingTime
        );
    }

    /// @notice Method for canceling listed NFT bundle
    function cancelListing(string memory _bundleID) external nonReentrant {
        bytes32 bundleID = _getBundleID(_bundleID);
        //checks bundle for listing 
        require(listings[_msgSender()][bundleID].price > 0, "not listed");
        //removes listing
        _cancelListing(_msgSender(), _bundleID);
    }

    /// @notice Method for updating listed NFT bundle
    /// @param _bundleID Bundle ID
    /// @param _newPrice New sale price for bundle
    function updateListing(
        string memory _bundleID,
        address _payToken,
        uint256 _newPrice
    ) external nonReentrant {
        bytes32 bundleID = _getBundleID(_bundleID);
        //gets listing with bundle id
        Listing storage listing = listings[_msgSender()][bundleID];

        //ensures that price is more than 0
        require(listing.price > 0, "not listed");

        //checks for valid token registry
        address tokenRegistry = addressRegistry.tokenRegistry();
        require(
            _payToken == address(0) ||
                (tokenRegistry != address(0) &&
                    ITokenRegistry(tokenRegistry).enabled(_payToken)),
            "invalid pay token"
        );

        //updates the pay token and price
        listing.payToken = _payToken;
        listing.price = _newPrice;

        emit ItemUpdated(
            _msgSender(),
            _bundleID,
            listing.nfts,
            listing.tokenIds,
            listing.quantities,
            _payToken,
            _newPrice
        );
    }

    /// @notice Method for buying listed NFT bundle
    /// @param _bundleID Bundle ID
    function buyItem(string memory _bundleID, address _payToken)
        external
        nonReentrant
    {
        bytes32 bundleID = _getBundleID(_bundleID);
        //gets bundle owner
        address owner = owners[bundleID];

        //make sure bundle id is valid and owner is available
        require(owner != address(0), "invalid id");

        //gets the listing and checks for valid pay token entered
        Listing memory listing = listings[owner][bundleID];
        require(listing.payToken == _payToken, "invalid pay token");

        _buyItem(_bundleID, _payToken);
    }

    //method for buying listed bundle
    function _buyItem(string memory _bundleID, address _payToken) private {
        //gets bundle id, owner and listing
        bytes32 bundleID = _getBundleID(_bundleID);
        address owner = owners[bundleID];
        Listing memory listing = listings[owner][bundleID];

        //ensures that listing exists with a valid price
        require(listing.price > 0, "not listed");

        //checks for nft ownership based on the nft's token standard
        for (uint256 i; i < listing.nfts.length; i++) {
            if (_supportsInterface(listing.nfts[i], INTERFACE_ID_ERC721)) {
                _check721Owning(listing.nfts[i], listing.tokenIds[i], owner);
            } else if (
                _supportsInterface(listing.nfts[i], INTERFACE_ID_ERC1155)
            ) {
                _check1155Owning(
                    listing.nfts[i],
                    listing.tokenIds[i],
                    listing.quantities[i],
                    owner
                );
            }
        }

        //makes sure that the current time is valid
        require(_getNow() >= listing.startingTime, "not buyable");

        uint256 price = listing.price;
        uint256 feeAmount = price * (platformFee) / (1e3);

        //transfer fees and owner price through native tokens
        if (_payToken == address(0)) {
            (bool feeTransferSuccess, ) = treasuryAddress.call{value: feeAmount}("");
            
            require(feeTransferSuccess, "aRarityMarketplace: Fee transfer failed");

            (bool ownerTransferSuccess, ) = owner.call{value: price - (feeAmount)}("");
            
            require(ownerTransferSuccess, "aRarityMarketplace: Owner transfer failed");

        } else {
            //pay fee and owner with a vlaid erc20 token
            IERC20(_payToken).safeTransferFrom(
                _msgSender(),
                treasuryAddress,
                feeAmount
            );
            IERC20(_payToken).safeTransferFrom(
                _msgSender(),
                owner,
                price - (feeAmount)
            );
        }

        // Transfer NFT to buyer from the owner according to the token standard
        for (uint256 i; i < listing.nfts.length; i++) {
            if (_supportsInterface(listing.nfts[i], INTERFACE_ID_ERC721)) {
                IERC721(listing.nfts[i]).safeTransferFrom(
                    owner,
                    _msgSender(),
                    listing.tokenIds[i]
                );
            } else {
                IERC1155(listing.nfts[i]).safeTransferFrom(
                    owner,
                    _msgSender(),
                    listing.tokenIds[i],
                    listing.quantities[i],
                    bytes("")
                );
            }

            //validates item sold, and removes it from the marketplace if it exists
            IMarketplace(addressRegistry.marketplace()).validateItemSold(
                listing.nfts[i],
                listing.tokenIds[i],
                owner,
                _msgSender()
            );
        }

        //deletes listing on the bundle marketplace
        delete (listings[owner][bundleID]);
        listing.price = 0;

        //updates listing with new owner
        listings[_msgSender()][bundleID] = listing;
        //updates new owner of bundleid
        owners[bundleID] = _msgSender();
        //deletes offers
        delete (offers[bundleID][_msgSender()]);

        emit ItemSold(
            owner,
            _msgSender(),
            _bundleID,
            _payToken,
            int(price),
            price
        );
        emit OfferCanceled(_msgSender(), _bundleID);
    }

    /// @notice Method for offering bundle item
    /// @param _bundleID Bundle ID
    /// @param _payToken Paying token
    /// @param _price Price
    /// @param _deadline Offer expiration
    function createOffer(
        string memory _bundleID,
        IERC20 _payToken,
        uint256 _price,
        uint256 _deadline
    ) external {
        //gets bundle id
        bytes32 bundleID = _getBundleID(_bundleID);

        //checks for valid owner, valid offer expiration, and price
        require(owners[bundleID] != address(0), "invalid id");
        require(_deadline > _getNow(), "invalid expiration");
        require(_price > 0, "invalid price");

        //creates offer and checks for existing offer based on the deadline
        Offer memory offer = offers[bundleID][_msgSender()];
        require(offer.deadline <= _getNow(), "offer exists");

        //updates the pay token, price and deadline
        offers[bundleID][_msgSender()] = Offer(_payToken, _price, _deadline);

        emit OfferCreated(
            _msgSender(),
            _bundleID,
            address(_payToken),
            _price,
            _deadline
        );
    }

    /// @notice Method for canceling the offer
    /// @param _bundleID Bundle ID
    function cancelOffer(string memory _bundleID) external {
        //gets bundle id and looks for the offer
        bytes32 bundleID = _getBundleID(_bundleID);
        Offer memory offer = offers[bundleID][_msgSender()];

        //checks if offer exists or expired 
        require(offer.deadline > _getNow(), "offer not exists or expired");

        //true -> deletes
        delete (offers[bundleID][_msgSender()]);
        emit OfferCanceled(_msgSender(), _bundleID);
    }

    /// @notice Method for accepting the offer
    function acceptOffer(string memory _bundleID, address _creator)
        external
        nonReentrant
    {
        //finds bundle id and checks if msgsender owns it
        bytes32 bundleID = _getBundleID(_bundleID);
        require(owners[bundleID] == _msgSender(), "not owning item");

        //checks for offer and checks for validity
        Offer memory offer = offers[bundleID][_creator];
        require(offer.deadline > _getNow(), "offer not exists or expired");

        //updates price and fee amount
        uint256 price = offer.price;
        uint256 feeAmount = price * (platformFee) / (1e3);

        //tranfer fee based on pay token
        offer.payToken.safeTransferFrom(_creator, treasuryAddress, feeAmount);
        //transfers to offer creator
        offer.payToken.safeTransferFrom(
            _creator,
            _msgSender(),
            price - (feeAmount)
        );

        

        //gets the listing based on function call
        Listing memory listing = listings[_msgSender()][bundleID];

        //checks for nft ownership based on the nft's token standard
        for (uint256 i; i < listing.nfts.length; i++) {
            if (_supportsInterface(listing.nfts[i], INTERFACE_ID_ERC721)) {
                _check721Owning(listing.nfts[i], listing.tokenIds[i], _msgSender());
            } else if (
                _supportsInterface(listing.nfts[i], INTERFACE_ID_ERC1155)
            ) {
                _check1155Owning(
                    listing.nfts[i],
                    listing.tokenIds[i],
                    listing.quantities[i],
                    _msgSender()
                );
            }
        }

        // Transfer NFT to buyer
        //sends the nft thats listed and offer that was made for the bundle
        for (uint256 i; i < listing.nfts.length; i++) {
            if (_supportsInterface(listing.nfts[i], INTERFACE_ID_ERC721)) {
                IERC721(listing.nfts[i]).safeTransferFrom(
                    _msgSender(),
                    _creator,
                    listing.tokenIds[i]
                );
            } else {
                IERC1155(listing.nfts[i]).safeTransferFrom(
                    _msgSender(),
                    _creator,
                    listing.tokenIds[i],
                    listing.quantities[i],
                    bytes("")
                );
            }

            //validates item being accepted offer, and removes any occurances from the marketplace
            IMarketplace(addressRegistry.marketplace()).validateItemSold(
                listing.nfts[i],
                listing.tokenIds[i],
                owners[bundleID],
                _creator
            );
        }
        //deletes listing
        delete (listings[_msgSender()][bundleID]);
        //resets price to 0
        listing.price = 0;
        //changes listings value to listing based on new owner which is the creator
        listings[_creator][bundleID] = listing;
        //changes the owner of the bundle
        owners[bundleID] = _creator;
        //removes the offer
        delete (offers[bundleID][_creator]);

        emit ItemSold(
            _msgSender(),
            _creator,
            _bundleID,
            address(offer.payToken),
            int(price),
            offer.price
        );
        emit OfferCanceled(_creator, _bundleID);
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint256 the platform fee to set
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient)
        external
        onlyOwner
    {
        treasuryAddress = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    /**
     @notice Update aRarityAddressRegistry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IAddressRegistry(_registry);
    }

    /**
     * @notice Validate and cancel listing
     * @dev Only marketplace can access
     */
    //checks listings on the bundle marketplace and removes it from the listing if its sold in the marketplace
    function validateItemSold(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _quantity
    ) external onlyContract {
        //checks the length of items in the bundle
        uint256 length = bundleIdsPerItem[_nftAddress][_tokenId].length();
        
        for (uint256 i; i < length; i++) {
            //gets the bundle id of the item listed
            bytes32 bundleID = bundleIdsPerItem[_nftAddress][_tokenId].at(i);
            //checks owner
            address _owner = owners[bundleID];
            
            //for valid owners
            if (_owner != address(0)) {
                //finds the listing
                Listing storage listing = listings[_owner][bundleID];
                //bundle id
                string memory _bundleID = bundleIds[bundleID];
                //nft index
                uint256 index = nftIndexes[bundleID][_nftAddress][_tokenId];

                //deducts the quantity if the listing quantity is higer
                if (listing.quantities[index] > _quantity) {
                    listing.quantities[index] = listing.quantities[index] - (_quantity);
                } else {
                    //if same or less, nft index is deleted
                    delete (nftIndexes[bundleID][_nftAddress][_tokenId]);
                    
                    //specific nft listing will be removed form the listing if theres only 1
                    if (listing.nfts.length == 1) {
                        delete (listings[_owner][bundleID]);
                        delete (owners[bundleID]);
                        delete (bundleIds[bundleID]);
                        emit ItemUpdated(
                            _owner,
                            _bundleID,
                            new address[](0),
                            new uint256[](0),
                            new uint256[](0),
                            address(0),
                            0
                        );

                        continue;
                    } else {

                        if (index < listing.nfts.length - 1) {
                            //nft length reduced
                            listing.nfts[index] = listing.nfts[
                                listing.nfts.length - 1
                            ];
                            //token id length reduced
                            listing.tokenIds[index] = listing.tokenIds[
                                listing.tokenIds.length - 1
                            ];
                            //listing quantity reduced
                            listing.quantities[index] = listing.quantities[
                                listing.quantities.length - 1
                            ];
                            //nft index reduced
                            nftIndexes[bundleID][listing.nfts[index]][
                                listing.tokenIds[index]
                            ] = index;
                        }
                        //listed item is removed from struct
                        listing.nfts.pop();
                        listing.tokenIds.pop();
                        listing.quantities.pop();
                    }
                }

                emit ItemUpdated(
                    _owner,
                    _bundleID,
                    listing.nfts,
                    listing.tokenIds,
                    listing.quantities,
                    listing.payToken,
                    listing.price
                );
            }
        }
        //bundle item is deleted
        delete (bundleIdsPerItem[_nftAddress][_tokenId]);
    }

    ////////////////////////////
    /// Internal and Private ///
    ////////////////////////////

    //checks if the interface is supported
    function _supportsInterface(address _addr, bytes4 iface)
        internal
        view
        returns (bool)
    {
        return IERC165(_addr).supportsInterface(iface);
    }

    //check the ownership for erc721
    function _check721Owning(
        address _nft,
        uint256 _tokenId,
        address _owner
    ) internal view {
        require(IERC721(_nft).ownerOf(_tokenId) == _owner, "not owning item");
    }

    //check the ownership for erc1155
    function _check1155Owning(
        address _nft,
        uint256 _tokenId,
        uint256 _quantity,
        address _owner
    ) internal view {
        require(
            IERC1155(_nft).balanceOf(_owner, _tokenId) >= _quantity,
            "not owning item"
        );
    }

    //gets timestamp
    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    //cancels the listing
    function _cancelListing(address _owner, string memory _bundleID) private {
        //gets bundle id
        bytes32 bundleID = _getBundleID(_bundleID);
        //gets listing
        Listing memory listing = listings[_owner][bundleID];

        for (uint256 i; i < listing.nfts.length; i++) {
            //removes bundle
            bundleIdsPerItem[listing.nfts[i]][listing.tokenIds[i]].remove(
                bundleID
            );
            //removes nft index
            delete (nftIndexes[bundleID][listing.nfts[i]][listing.tokenIds[i]]);
        }
        //deletes listings, owner, and bundle id
        delete (listings[_owner][bundleID]);
        delete (owners[bundleID]);
        delete (bundleIds[bundleID]);
        emit ItemCanceled(_owner, _bundleID);
    }

    //retrieves the bundle id as a hashed string
    function _getBundleID(string memory _bundleID)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_bundleID));
    }
}
