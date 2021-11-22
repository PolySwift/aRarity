// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

interface ARarityInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
    function getTokenRarity(uint256 tokenId) external view returns(string memory);
}

contract MintTemplate is ERC721, Ownable, ReentrancyGuard, Pausable {

    using SafeERC20 for IERC20;

    uint256 public immutable MAX_NFT_SUPPLY = 25000;
    uint256 public NFT_PRICE; 

    IERC20 public usdcToken;
    address public treasury;

    constructor(
        string memory name,
        string memory symbol,
        address _tokenAddress,
        address _treasury,
        uint _price
    ) ERC721(name, symbol) {
        usdcToken = IERC20(_tokenAddress);
        treasury = _treasury;
        NFT_PRICE = _price;
    }

    ARarityInterface aRarityContract = ARarityInterface(0x22708088143a12c08182c0112B1880502EAADa8e);

    function setPrice(uint _price) external onlyOwner {
        NFT_PRICE = _price;
    }

    function mintToken(uint tokenId) public nonReentrant whenNotPaused {
        require(tokenId <= MAX_NFT_SUPPLY, "Exceeds Max Supply for aRarity");
        require(aRarityContract.balanceOf(msg.sender) > 0, "Must own an aRarity to mint token");
        require(aRarityContract.ownerOf(tokenId) == msg.sender, "Cannot mint a token that isnt based on your existing");

        usdcToken.safeTransferFrom(address(msg.sender), treasury, NFT_PRICE);

        _safeMint(msg.sender, tokenId);

    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    string[] private commonWeapons = [
        "Warhammer",
        "Quarterstaff",
        "Maul"
    ];

    string[] private uncommonWeapons = [
        "Mace",
        "Club",
        "Katana"
    ];

    string[] private epicWeapons = [
        "Falchion",
        "Scimitar",
        "Long Sword"
    ];

    string[] private rareWeapons = [
        "Short Sword",
        "Ghost Wand",
        "Grave Wand"
    ];

    string[] private ultraWeapons = [
        "Bone Wand",
        "Wand",
        "Grimoire"
    ];

    string[] private godlikeWeapons = [
        "Chronicle",
        "Tome",
        "Book"
    ];

    string[] private commonChestArmor = [
        "Chain Mail",
        "Ring Mail"
    ];

    string[] private uncommonChestArmor = [
        "Ornate Chestplate",
        "Plate Mail"
    ];

    string[] private epicChestArmor = [
        "Studded Leather Armor",
        "Hard Leather Armor"
    ];

    string[] private rareChestArmor = [
        "Leather Armor",
        "Holy Chestplate"
    ];

    string[] private ultraChestArmor = [
        "Silk Robe",
        "Linen Robe",
        "Robe",
        "Shirt"
    ];

    string[] private godlikeChestArmor = [
        "Divine Robe",
        "Demon Husk",
        "Dragonskin Armor"
    ];
    
    string[] private commonHeadArmor = [
        "Silk Hood",
        "Linen Hood",
        "Hood"
    ];

    string[] private uncommonHeadArmor = [
        "War Cap",
        "Leather Cap",
        "Cap"
    ];

    string[] private epicHeadArmor = [
        "Helm",
        "Cap",
        "Crown"
    ];

    string[] private rareHeadArmor = [
        "Crown",
        "Ornate Helm",
        "Great Helm"
    ];

    string[] private ultraHeadArmor = [
        "Ancient Helm",
        "Ornate Helm",
        "Great Helm"
    ];

    string[] private godlikeHeadArmor = [
        
        "Demon Crown",
        "Dragon's Crown",
        "Divine Hood"
    ];
    
    string[] private commonWaistArmor = [
        "Wool Sash",
        "Linen Sash",
        "Sash"
    ];

    string[] private uncommonWaistArmor = [
        "Leather Belt",
        "Brightsilk Sash",
        "Silk Sash"
    ];

    string[] private epicWaistArmor = [
        "Mesh Belt",
        "Studded Leather Belt",
        "Hard Leather Belt"
    ];

    string[] private rareWaistArmor = [
        "Mesh Belt",
        "War Belt",
        "Plated Belt"
    ];

    string[] private ultraWaistArmor = [
        "War Belt",
        "Plated Belt",
        "Heavy Belt"
    ];

    string[] private godlikeWaistArmor = [
        "Ornate Belt",
        "Demonhide Belt",
        "Dragonskin Belt"
        
    ];
    
    string[] private commonFootArmor = [
        "Wool Shoes",
        "Linen Shoes",
        "Shoes"
    ];

    string[] private uncommonFootArmor = [
        "Hard Leather Boots",
        "Leather Boots",
        "Silk Slippers"
    ];

    string[] private epicFootArmor = [
        "Hard Leather Boots",
        "Leather Boots"
    ];

    string[] private rareFootArmor = [
        "Greaves",
        "Chain Boots",
        "Heavy Boots"
    ];

    string[] private ultraFootArmor = [
        "Holy Greaves",
        "Ornate Greaves",
        "Divine Slippers"
    ];

    string[] private godlikeFootArmor = [
        "Demonhide Boots",
        "Dragonskin Boots"
    ];
    
    string[] private commonHandArmor = [
        "Wool Gloves",
        "Linen Gloves",
        "Gloves"
    ];

    string[] private uncommonHandArmor = [
        "Gauntlets",
        "Leather Gloves",
        "Silk Gloves"
    ];

    string[] private epicHandArmor = [
        "Studded Leather Gloves",
        "Hard Leather Gloves"
    ];

    string[] private rareHandArmor = [
        "Ornate Gauntlets",
        "Chain Gloves",
        "Heavy Gloves"
    ];

    string[] private ultraHandArmor = [
        "Holy Gauntlets",
        "Ornate Gauntlets",
        "Divine Gloves"
    ];

    string[] private godlikeHandArmor = [
        "Demon's Hands",
        "Dragonskin Gloves",
        "Divine Gloves"
    ];
    
    string[] private necklaces = [
        "Necklace",
        "Amulet",
        "Pendant"
    ];
    
    string[] private rings = [
        "Gold Ring",
        "Silver Ring",
        "Bronze Ring",
        "Platinum Ring",
        "Titanium Ring"
    ];
    
    string[] private suffixes = [
        "of Power",
        "of Giants",
        "of Titans",
        "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Enlightenment",
        "of Protection",
        "of Anger",
        "of Rage",
        "of Fury",
        "of Vitriol",
        "of the Fox",
        "of Detection",
        "of Reflection",
        "of the Twins"
    ];
    
    string[] private namePrefixes = [
        "Agony", 
        "Apocalypse", 
        "Armageddon", 
        "Beast", 
        "Behemoth", 
        "Blight", 
        "Blood", 
        "Bramble", 
        "Brimstone", 
        "Brood", 
        "Carrion", 
        "Cataclysm", 
        "Chimeric", 
        "Corpse", 
        "Corruption", 
        "Damnation"
    ];
    
    string[] private nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
        "Roar",
        "Grasp",
        "Instrument",
        "Glow",
        "Bender",
        "Shadow",
        "Whisper"
    ];


    function getCommonEquipment(string memory eqptType, uint256 tokenId) public view returns (string memory) {
        bytes memory eqpt = bytes(eqptType);

        if(keccak256(eqpt) == keccak256("WEAPON")){
            return pluck(tokenId, "WEAPON", commonWeapons);
        }else if(keccak256(eqpt) == keccak256("ARMOR")){
            return pluck(tokenId, "ARMOR", commonChestArmor);
        }else if(keccak256(eqpt) == keccak256("HELMET")){
            return pluck(tokenId, "HELMET", commonHeadArmor);
        }else if(keccak256(eqpt) == keccak256("WAIST")){
            return pluck(tokenId, "WAIST", commonWaistArmor);
        }else if(keccak256(eqpt) == keccak256("LEGGING")){
            return pluck(tokenId, "LEGGING", commonFootArmor);
        }else if(keccak256(eqpt) == keccak256("HAND")){
            return pluck(tokenId, "HAND", commonHandArmor);
        }else if(keccak256(eqpt) == keccak256("NECK")){
            return pluck(tokenId, "NECK", necklaces);
        }else if(keccak256(eqpt) == keccak256("RING")){
            return pluck(tokenId, "RING", rings);
        }
    }

    function getUncommonEquipment(string memory eqptType, uint256 tokenId) public view returns (string memory) {
        bytes memory eqpt = bytes(eqptType);

        if(keccak256(eqpt) == keccak256("WEAPON")){
            return pluck(tokenId, "WEAPON", uncommonWeapons);
        }else if(keccak256(eqpt) == keccak256("ARMOR")){
            return pluck(tokenId, "ARMOR", uncommonChestArmor);
        }else if(keccak256(eqpt) == keccak256("HELMET")){
            return pluck(tokenId, "HELMET", uncommonHeadArmor);
        }else if(keccak256(eqpt) == keccak256("WAIST")){
            return pluck(tokenId, "WAIST", uncommonWaistArmor);
        }else if(keccak256(eqpt) == keccak256("LEGGING")){
            return pluck(tokenId, "LEGGING", uncommonFootArmor);
        }else if(keccak256(eqpt) == keccak256("HAND")){
            return pluck(tokenId, "HAND", uncommonHandArmor);
        }else if(keccak256(eqpt) == keccak256("NECK")){
            return pluck(tokenId, "NECK", necklaces);
        }else if(keccak256(eqpt) == keccak256("RING")){
            return pluck(tokenId, "RING", rings);
        }
    }

    function getEpicEquipment(string memory eqptType, uint256 tokenId) public view returns (string memory) {
        bytes memory eqpt = bytes(eqptType);

        if(keccak256(eqpt) == keccak256("WEAPON")){
            return pluck(tokenId, "WEAPON", epicWeapons);
        }else if(keccak256(eqpt) == keccak256("ARMOR")){
            return pluck(tokenId, "ARMOR", epicChestArmor);
        }else if(keccak256(eqpt) == keccak256("HELMET")){
            return pluck(tokenId, "HELMET", epicHeadArmor);
        }else if(keccak256(eqpt) == keccak256("WAIST")){
            return pluck(tokenId, "WAIST", epicWaistArmor);
        }else if(keccak256(eqpt) == keccak256("LEGGING")){
            return pluck(tokenId, "LEGGING", epicFootArmor);
        }else if(keccak256(eqpt) == keccak256("HAND")){
            return pluck(tokenId, "HAND", epicHandArmor);
        }else if(keccak256(eqpt) == keccak256("NECK")){
            return pluck(tokenId, "NECK", necklaces);
        }else if(keccak256(eqpt) == keccak256("RING")){
            return pluck(tokenId, "RING", rings);
        }
    }

    function getRareEquipment(string memory eqptType, uint256 tokenId) public view returns (string memory) {
        bytes memory eqpt = bytes(eqptType);

        if(keccak256(eqpt) == keccak256("WEAPON")){
            return pluck(tokenId, "WEAPON", rareWeapons);
        }else if(keccak256(eqpt) == keccak256("ARMOR")){
            return pluck(tokenId, "ARMOR", rareChestArmor);
        }else if(keccak256(eqpt) == keccak256("HELMET")){
            return pluck(tokenId, "HELMET", rareHeadArmor);
        }else if(keccak256(eqpt) == keccak256("WAIST")){
            return pluck(tokenId, "WAIST", rareWaistArmor);
        }else if(keccak256(eqpt) == keccak256("LEGGING")){
            return pluck(tokenId, "LEGGING", rareFootArmor);
        }else if(keccak256(eqpt) == keccak256("HAND")){
            return pluck(tokenId, "HAND", rareHandArmor);
        }else if(keccak256(eqpt) == keccak256("NECK")){
            return pluck(tokenId, "NECK", necklaces);
        }else if(keccak256(eqpt) == keccak256("RING")){
            return pluck(tokenId, "RING", rings);
        }
    }

    function getUltraEquipment(string memory eqptType, uint256 tokenId) public view returns (string memory) {
        bytes memory eqpt = bytes(eqptType);

        if(keccak256(eqpt) == keccak256("WEAPON")){
            return pluck(tokenId, "WEAPON", ultraWeapons);
        }else if(keccak256(eqpt) == keccak256("ARMOR")){
            return pluck(tokenId, "ARMOR", ultraChestArmor);
        }else if(keccak256(eqpt) == keccak256("HELMET")){
            return pluck(tokenId, "HELMET", ultraHeadArmor);
        }else if(keccak256(eqpt) == keccak256("WAIST")){
            return pluck(tokenId, "WAIST", ultraWaistArmor);
        }else if(keccak256(eqpt) == keccak256("LEGGING")){
            return pluck(tokenId, "LEGGING", ultraFootArmor);
        }else if(keccak256(eqpt) == keccak256("HAND")){
            return pluck(tokenId, "HAND", ultraHandArmor);
        }else if(keccak256(eqpt) == keccak256("NECK")){
            return pluck(tokenId, "NECK", necklaces);
        }else if(keccak256(eqpt) == keccak256("RING")){
            return pluck(tokenId, "RING", rings);
        }
    }

    function getGodlikeEquipment(string memory eqptType, uint256 tokenId) public view returns (string memory) {
        bytes memory eqpt = bytes(eqptType);

        if(keccak256(eqpt) == keccak256("WEAPON")){
            return pluck(tokenId, "WEAPON", godlikeWeapons);
        }else if(keccak256(eqpt) == keccak256("ARMOR")){
            return pluck(tokenId, "ARMOR", godlikeChestArmor);
        }else if(keccak256(eqpt) == keccak256("HELMET")){
            return pluck(tokenId, "HELMET", godlikeHeadArmor);
        }else if(keccak256(eqpt) == keccak256("WAIST")){
            return pluck(tokenId, "WAIST", godlikeWaistArmor);
        }else if(keccak256(eqpt) == keccak256("LEGGING")){
            return pluck(tokenId, "LEGGING", godlikeFootArmor);
        }else if(keccak256(eqpt) == keccak256("HAND")){
            return pluck(tokenId, "HAND", godlikeHandArmor);
        }else if(keccak256(eqpt) == keccak256("NECK")){
            return pluck(tokenId, "NECK", necklaces);
        }else if(keccak256(eqpt) == keccak256("RING")){
            return pluck(tokenId, "RING", rings);
        }
    }

    function getCommon(uint256 tokenId) internal view returns (string memory) {
        string[15] memory parts;

        parts[0] = getCommonEquipment("WEAPON", tokenId);

        parts[1] = '</text><text x="10" y="40" class="base">';

        parts[2] = getCommonEquipment("ARMOR", tokenId);

        parts[3] = '</text><text x="10" y="60" class="base">';

        parts[4] = getCommonEquipment("HELMET", tokenId);

        parts[5] = '</text><text x="10" y="80" class="base">';

        parts[6] = getCommonEquipment("WAIST", tokenId);

        parts[7] = '</text><text x="10" y="100" class="base">';

        parts[8] = getCommonEquipment("LEGGING", tokenId);

        parts[9] = '</text><text x="10" y="120" class="base">';

        parts[10] = getCommonEquipment("HAND", tokenId);

        parts[11] = '</text><text x="10" y="140" class="base">';

        parts[12] = getCommonEquipment("NECK", tokenId);

        parts[13] = '</text><text x="10" y="160" class="base">';

        parts[14] = getCommonEquipment("RING", tokenId);

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        return output;
    }

    function getUncommon(uint256 tokenId) internal view returns (string memory) {
        string[15] memory parts;

        parts[0] = getUncommonEquipment("WEAPON", tokenId);

        parts[1] = '</text><text x="10" y="40" class="base">';

        parts[2] = getUncommonEquipment("ARMOR", tokenId);

        parts[3] = '</text><text x="10" y="60" class="base">';

        parts[4] = getUncommonEquipment("HELMET", tokenId);

        parts[5] = '</text><text x="10" y="80" class="base">';

        parts[6] = getUncommonEquipment("WAIST", tokenId);

        parts[7] = '</text><text x="10" y="100" class="base">';

        parts[8] = getUncommonEquipment("LEGGING", tokenId);

        parts[9] = '</text><text x="10" y="120" class="base">';

        parts[10] = getUncommonEquipment("HAND", tokenId);

        parts[11] = '</text><text x="10" y="140" class="base">';

        parts[12] = getUncommonEquipment("NECK", tokenId);

        parts[13] = '</text><text x="10" y="160" class="base">';

        parts[14] = getUncommonEquipment("RING", tokenId);

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        return output;
        
    }

    function getEpic(uint256 tokenId) internal view returns (string memory) {
        string[15] memory parts;

        parts[0] = getEpicEquipment("WEAPON", tokenId);

        parts[1] = '</text><text x="10" y="40" class="base">';

        parts[2] = getEpicEquipment("ARMOR", tokenId);

        parts[3] = '</text><text x="10" y="60" class="base">';

        parts[4] = getEpicEquipment("HELMET", tokenId);

        parts[5] = '</text><text x="10" y="80" class="base">';

        parts[6] = getEpicEquipment("WAIST", tokenId);

        parts[7] = '</text><text x="10" y="100" class="base">';

        parts[8] = getEpicEquipment("LEGGING", tokenId);

        parts[9] = '</text><text x="10" y="120" class="base">';

        parts[10] = getEpicEquipment("HAND", tokenId);

        parts[11] = '</text><text x="10" y="140" class="base">';

        parts[12] = getEpicEquipment("NECK", tokenId);

        parts[13] = '</text><text x="10" y="160" class="base">';

        parts[14] = getEpicEquipment("RING", tokenId);

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        return output;

    }

    function getRare(uint256 tokenId) internal view returns (string memory) {
        string[15] memory parts;

        parts[0] = getRareEquipment("WEAPON", tokenId);

        parts[1] = '</text><text x="10" y="40" class="base">';

        parts[2] = getRareEquipment("ARMOR", tokenId);

        parts[3] = '</text><text x="10" y="60" class="base">';

        parts[4] = getRareEquipment("HELMET", tokenId);

        parts[5] = '</text><text x="10" y="80" class="base">';

        parts[6] = getRareEquipment("WAIST", tokenId);

        parts[7] = '</text><text x="10" y="100" class="base">';

        parts[8] = getRareEquipment("LEGGING", tokenId);

        parts[9] = '</text><text x="10" y="120" class="base">';

        parts[10] = getRareEquipment("HAND", tokenId);

        parts[11] = '</text><text x="10" y="140" class="base">';

        parts[12] = getRareEquipment("NECK", tokenId);

        parts[13] = '</text><text x="10" y="160" class="base">';

        parts[14] = getRareEquipment("RING", tokenId);

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        return output;

    }

    function getUltra(uint256 tokenId) internal view returns (string memory) {
        string[15] memory parts;

        parts[0] = getUltraEquipment("WEAPON", tokenId);

        parts[1] = '</text><text x="10" y="40" class="base">';

        parts[2] = getUltraEquipment("ARMOR", tokenId);

        parts[3] = '</text><text x="10" y="60" class="base">';

        parts[4] = getUltraEquipment("HELMET", tokenId);

        parts[5] = '</text><text x="10" y="80" class="base">';

        parts[6] = getUltraEquipment("WAIST", tokenId);

        parts[7] = '</text><text x="10" y="100" class="base">';

        parts[8] = getUltraEquipment("LEGGING", tokenId);

        parts[9] = '</text><text x="10" y="120" class="base">';

        parts[10] = getUltraEquipment("HAND", tokenId);

        parts[11] = '</text><text x="10" y="140" class="base">';

        parts[12] = getUltraEquipment("NECK", tokenId);

        parts[13] = '</text><text x="10" y="160" class="base">';

        parts[14] = getUltraEquipment("RING", tokenId);

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        return output;
        
    }

    function getGodlike(uint256 tokenId) internal view returns (string memory) {
        string[15] memory parts;

        parts[0] = getGodlikeEquipment("WEAPON", tokenId);

        parts[1] = '</text><text x="10" y="40" class="base">';

        parts[2] = getGodlikeEquipment("ARMOR", tokenId);

        parts[3] = '</text><text x="10" y="60" class="base">';

        parts[4] = getGodlikeEquipment("HELMET", tokenId);

        parts[5] = '</text><text x="10" y="80" class="base">';

        parts[6] = getGodlikeEquipment("WAIST", tokenId);

        parts[7] = '</text><text x="10" y="100" class="base">';

        parts[8] = getGodlikeEquipment("LEGGING", tokenId);

        parts[9] = '</text><text x="10" y="120" class="base">';

        parts[10] = getGodlikeEquipment("HAND", tokenId);

        parts[11] = '</text><text x="10" y="140" class="base">';

        parts[12] = getGodlikeEquipment("NECK", tokenId);

        parts[13] = '</text><text x="10" y="160" class="base">';

        parts[14] = getGodlikeEquipment("RING", tokenId);

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        return output;
        
    }


    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        
        return output;

    }



    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        bytes memory rares = bytes(aRarityContract.getTokenRarity(tokenId));

        string[3] memory rarity;
        rarity[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        if(_exists(tokenId)){
            if(keccak256(rares) == keccak256("Common")){
                rarity[1] = getCommon(tokenId);
            }else if(keccak256(rares) == keccak256("Uncommon")){
                rarity[1] = getUncommon(tokenId);
            }else if(keccak256(rares) == keccak256("Epic")){
                rarity[1] = getEpic(tokenId);
            }else if(keccak256(rares) == keccak256("Rare")){
                rarity[1] = getRare(tokenId);
            }else if(keccak256(rares) == keccak256("Ultra Rare")){
                rarity[1] = getUltra(tokenId);
            }else if(keccak256(rares) == keccak256("Godlike")){
                rarity[1] = getGodlike(tokenId);
            }else if(keccak256(rares) == keccak256("Token is not minted")){
                rarity[1] = 'Token is not minted';
            }
        }else{
            rarity[1] = 'Token is not minted';
        }

        rarity[2] = '</text></svg>';

        string memory output = string(abi.encodePacked(rarity[0], rarity[1], rarity[2]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Rare is randomized rarity generator stored on chain. Items, stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Rare in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
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

    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}