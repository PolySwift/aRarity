//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface ARarityInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract RefundNFT is Ownable, ReentrancyGuard, Pausable {

    using SafeERC20 for IERC20;
    
    event NFTRefunded(
        address claimer,
        uint256 tokenId
    );
    
    struct refundStatus {
        bool claimed;
        address claimer;
    }

    mapping(uint => refundStatus) public refunded;

    IERC20 usdcToken = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    ARarityInterface aRarityContract = ARarityInterface(0x22708088143a12c08182c0112B1880502EAADa8e);

    function depositFundsForRefund(uint _fundsAmount) public nonReentrant {
        
        usdcToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _fundsAmount
        );
    }

    function withdrawFunds(uint _amount) public onlyOwner nonReentrant{
        
        usdcToken.safeTransfer(address(msg.sender), _amount);

    }

    function getBalance() public view returns(uint256){
        uint256 balance = usdcToken.balanceOf(address(this));
        
        return balance;
    }

    function claimRefund(uint32[] memory _nftID) public nonReentrant{
        require(aRarityContract.balanceOf(msg.sender) > 0, "Must own an aRarity to mint token");

        for(uint i = 0; i < _nftID.length; i++){
            
            require( _nftID[i] >= 250, "Cant claim nft obtained from giveaway");
            require(aRarityContract.ownerOf(_nftID[i]) == msg.sender, "Cannot mint a token that isnt based on your existing");
            require(refunded[_nftID[i]].claimed == false, "This nft has already been claimed");

            refunded[_nftID[i]].claimed = true;
            refunded[_nftID[i]].claimer = msg.sender;

            emit NFTRefunded(msg.sender, _nftID[i]);

        }
                
        usdcToken.safeTransfer(address(msg.sender), 15000000 * _nftID.length);

    }
}
