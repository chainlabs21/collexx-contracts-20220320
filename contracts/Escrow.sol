pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Interfaces/IERC1155.sol";
import "./Interfaces/IERC721.sol";
//import "./Tangible_Fixed.sol";
// import "./Tangible_offer.sol";
// import "./Tangible_auction.sol";

contract Escrow { //TangibleSpot  SuggestToSell, TangibleAuction
    struct EscrowInfo {
        address paymentaddress;
        address buyer;
        address seller;
        uint256 tokenid;
        uint256 price;
        uint256 deliveryfee;
    }
    mapping (address => mapping(address=> uint256)) public _map_token_balance;
    mapping (address => mapping(address=>uint256)) public _map_nft_balance;
    mapping (string => EscrowInfo) public _uuid_escrow_info;
    address _admincontract;

    constructor(
        address __admincontract
    ){
        _admincontract = __admincontract;
    }

    function set_admincontract(address __admincontract) public {
        _admincontract = __admincontract;
    }

    function verifySig(bytes32 _hashMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address){
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function set_claimed(address __nftcontract, string memory itemid, bool isMultiple) public {
        uint256 tokenid;
        if(isMultiple){
            tokenid = IERC1155(__nftcontract)._itemhash_tokenid(itemid);
            require(tokenid>0, "ESCROW ERR(): Invalid ERC1155 itemid");
            IERC1155(__nftcontract)._tokenid_isclaimed(tokenid);
        }else{
            tokenid = IERC721(__nftcontract)._itemhash_tokenid(itemid);
            require(tokenid>0, "ESCROW ERR(): Invalid ERC721 itemid");
            IERC1155(__nftcontract)._tokenid_isclaimed(tokenid);
        }
        
    }


}