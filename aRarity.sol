// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./whitelist.sol";

contract ARarity is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using SafeERC20 for IERC20;

    uint256 public immutable MAX_NFT_SUPPLY = 25000;

    IERC20 public usdcToken;
    address public treasury;
    bool public hasOwnerMint;
    Whitelist public whitelist;

    constructor(
        address _tokenAddress,
        address _treasury,
        address _whitelistAddress
    ) ERC721("aRarity", "aRarity") {
        usdcToken = IERC20(_tokenAddress);
        treasury = _treasury;
        hasOwnerMint = false;
        whitelist = Whitelist(_whitelistAddress);
    }

    struct Tier {
        uint256 MAX_SUPPLY;
        uint256 price;
    }

    Tier public tier;

    function addTierDetails(uint256 _maxSupply, uint256 _price)
        external
        onlyOwner
    {
        require(
            _maxSupply <= MAX_NFT_SUPPLY,
            "Max Tier supply cant be more than max total supply"
        );

        tier.MAX_SUPPLY = _maxSupply;
        tier.price = _price;
    }

    function getTierDetails()
        public
        view
        returns (uint256 maxSupply, uint256 price)
    {
        return (tier.MAX_SUPPLY, tier.price);
    }

    function getCurrentSupply() public view returns (uint256) {
        uint256 currentSupply = _tokenIds.current();
        return currentSupply;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    string[] private tierRarity = [
        "Common",
        "Uncommon",
        "Epic",
        "Rare",
        "Ultra Rare",
        "Godlike"
    ];

    function getRarity(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "RARITY", tierRarity);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        string memory output;
        uint256 greatness = rand % 1000;

        if (greatness < 500) {
            output = sourceArray[0];
            return output;
        } else if (greatness < 800) {
            output = sourceArray[1];
            return output;
        } else if (greatness < 950) {
            output = sourceArray[2];
            return output;
        } else if (greatness < 990) {
            output = sourceArray[3];
            return output;
        } else if (greatness < 998) {
            output = sourceArray[4];
            return output;
        } else if (greatness < 1000) {
            output = sourceArray[5];
            return output;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bytes memory rares = bytes(getTokenRarity(tokenId));

        string[5] memory rarity;
        rarity[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: ';
        
        if(keccak256(rares) == keccak256("Common")){
                rarity[1] = 'white';
            }else if(keccak256(rares) == keccak256("Uncommon")){
                rarity[1] = '#ffffff';
            }else if(keccak256(rares) == keccak256("Epic")){
                rarity[1] = '#84E86C';
            }else if(keccak256(rares) == keccak256("Rare")){
                rarity[1] = 'blue';
            }else if(keccak256(rares) == keccak256("Ultra Rare")){
                rarity[1] = 'hotpink';
            }else if(keccak256(rares) == keccak256("Godlike")){
                rarity[1] = 'gold';
            }else if(keccak256(rares) == keccak256("Token is not minted")){
                rarity[1] = 'white';
            }
        // white
        
        rarity[2] = '; font-family: serif; font-size: 40px; }</style><rect width="100%" height="100%" fill="black" /><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">';

        if (_exists(tokenId)) {
            rarity[3] = getRarity(tokenId);
        } else {
            rarity[3] = "Token is not minted";
        }

        rarity[4] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(rarity[0], rarity[1], rarity[2], rarity[3], rarity[4])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "aRarity #',
                        toString(tokenId),
                        '", "description": "aRarity is randomized rarity generator stored on chain. Projects intending to build on top of aRarity are expected to create their own themed NFT collection which will then be minted by an aRarity holder.",',
                        '"traits":[{"trait_type": "Rarity", "value": "',
                        rarity[3],
                        '"}],',
                        '"rarity": "',
                        rarity[3],
                        '","image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function getTokenRarity(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        string memory rarity;

        if (_exists(tokenId)) {
            rarity = getRarity(tokenId);
        } else {
            rarity = "Token is not minted";
        }

        return rarity;
    }

    function mintNFT(address recipient, uint256 amount)
        public
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        if (whitelist.whitelistEnabled()) {
            require(
                whitelist.isWhitelisted(msg.sender),
                "Address not whitelisted"
            );
        }

        require(
            tier.MAX_SUPPLY > 0 && tier.price > 0,
            "Tier Details has not been set"
        );
        require(getCurrentSupply() <= MAX_NFT_SUPPLY, "Sale has already ended");
        require(amount > 0, "Amount to purchase cannot be 0");
        require(
            getCurrentSupply() + amount <= MAX_NFT_SUPPLY,
            "Exceeds MAX_NFT_SUPPLY"
        );
        require(
            getCurrentSupply() + amount <= tier.MAX_SUPPLY,
            "Exceeds Tier Supply"
        );

        usdcToken.safeTransferFrom(
            address(msg.sender),
            treasury,
            tier.price * amount
        );

        uint256 newItemId = _tokenIds.current();

        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();

            newItemId = _tokenIds.current();
            _safeMint(recipient, newItemId);
        }

        return newItemId;
    }

    function ownerMintNFT() public nonReentrant whenNotPaused onlyOwner {
        require(hasOwnerMint == false, "Owner has already minted");

        uint256 newItemId = _tokenIds.current();

        for (uint256 i = 0; i < 250; i++) {
            _tokenIds.increment();

            newItemId = _tokenIds.current();
            _safeMint(this.owner(), newItemId);
        }
        hasOwnerMint = true;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setWhitelist(address _whitelist) external onlyOwner {
        whitelist = Whitelist(_whitelist);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
