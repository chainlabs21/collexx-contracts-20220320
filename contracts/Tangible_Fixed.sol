pragma solidity ^0.8.0;
import "./Interfaces/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/IVerify-signature.sol" ;
import "./Interfaces/IERC1155.sol";
import "./Interfaces/ISaleInfo.sol";
import "./utils/Signing_admins.sol";
import "./Interfaces/IAdmin_nft.sol";
import "hardhat/console.sol";

interface Interface_to_vault {
	enum SEND_TYPES {
			BID_DUTCH_BULK
		, BID_DUTCH_PIECES
		, BID_ENGLISH

		, ADMIN_FEE_SPOT
		, ADMIN_FEE_AUCTION_DUTCH_PIECES
		, ADMIN_FEE_AUCTION_DUTCH_BULK
		, ADMIN_FEE_AUCTION_ENGLISH

		, REFERER_FEE_DEPOSIT
		, AUTHOR_ROYALTY_DEPOSIT 
	}
	event DepositToVault (
			address _from
		, uint256 _amount
		, uint256 _type
		, address _to //		, uint256 _tokenid_or_batchid
	) ;
	event PaidFee (
			address _from
		, uint256 _amount
		, uint256 _type
		, address _to //		, uint256 _tokenid_or_batchid
	);
}

contract TangibleSpot is 
ERC1155MockReceiver , 
SaleInfo , 
Ownable , 
Signing_admins, 
Interface_to_vault//, IAdmin_nft 
{	 
	
	mapping ( string => Sale_info ) public _map_sale_info ;
	mapping ( string => Pay_info ) public _map_pay_info ;
	mapping (string => bool) public _map_uuid_issue;
	address public _verify_signature_lib ;
	address public _contractowner;
	address public _admincontract;
	
	constructor ( address __verify_signature_lib, address __admincontract ) {
		_verify_signature_lib = __verify_signature_lib ;
		_contractowner = msg.sender ;
		_admincontract = __admincontract;
	}

	function makepayment (
		address _paymeansaddress
		, uint256 _amounttopay
		, address _receiver
	) internal {
		if ( _paymeansaddress == address(0) ){
			payable( _receiver).call {value : _amounttopay } ("");
		}
		else {
			IERC20 ( _paymeansaddress ).transfer ( _receiver , _amounttopay ) ;
		}
	}

	

	function set_with_admin_privilege ( string memory _uuid
		, Sale_info memory saleinfo
		, Pay_info memory payinfo
	 ) public {
		 require ( _signing_admins[ msg.sender ] , "ERR() not privileged" );		 
		_map_sale_info [ _uuid ] = saleinfo ;
		_map_pay_info[ _uuid ] = payinfo ;
	}

	function verify_done_delivery_signature ( string memory _uuid 
		, Signature memory _sig_done_delivery 
		, address _signing_admin
	) public returns ( bool ) {
		bytes memory data = abi.encodePacked ( 'Done delivery' , _uuid );
		bytes32  datahash = keccak256 ( data ) ;
		address recoveredaddress =IVerify_signature( _verify_signature_lib ). recoverSigner ( datahash , _sig_done_delivery._signature );
		return recoveredaddress == _signing_admin ;
	}

	function mint_and_escrow_to_buy (
			Mint_info memory mintinfo
		, Signature memory mintsignature
		, Sale_info memory saleinfo
		, Signature memory salesignature
		//, Pay_info memory payinfo
	) public payable returns ( string memory ) {
		/****** mint  as usual */
		uint256 tokenid = IERC1155 ( mintinfo._target_erc1155_contract)._itemhash_tokenid ( mintinfo._itemid ) ;
		if ( tokenid == 0 ) {
			tokenid = IERC1155 ( mintinfo._target_erc1155_contract ).mint (
				mintinfo._author
				, mintinfo._itemid
				, mintinfo.revealedhash
				, mintinfo._amounttomint
				, mintinfo._author_royalty
				, mintinfo._decimals
				, "0x00"
			) ;
		}
		/******* pull payment and item */
		if (saleinfo._claimed == true && IERC1155(mintinfo._target_erc1155_contract)._tokenid_isclaimed(tokenid) == true){ //if claimed?
			if ( saleinfo._paymeansaddress == address(0) ) { 
				if (  msg.value >= saleinfo._offerprice){}
				else {revert("ERR() value does not meet price");}
			} else {
				if ( IERC20( saleinfo._paymeansaddress).transferFrom( msg.sender , address(this) , saleinfo._offerprice) ){
				}
				else {revert("ERR() value does not meet price"); }
			}
			IERC1155 ( saleinfo._target_erc1155_contract ).safeTransferFrom (
				saleinfo._seller
				, address ( this )
				, tokenid
				, saleinfo._amounttosell
				, "0x00"
			) ;		
			if ( _map_sale_info [ saleinfo._uuid ]._status ){revert("ERR() sale info already exists") ; } 
			else {}
			/****** register pay info */
			_map_sale_info[ saleinfo._uuid ] = saleinfo ;
			_map_pay_info [ saleinfo._uuid ] = Pay_info (
				msg.sender , saleinfo._itemid , tokenid , saleinfo._amounttosell , true , saleinfo._uuid
			);
			saleinfo._expiry = block.timestamp;
			return "CLAIMED";
		}else{	//If not claimed. NFT Transfer Only.
			// if ( saleinfo._paymeansaddress == address(0) ) { //Native
			// 	if (  msg.value >= saleinfo._offerprice){
			// 		payable(saleinfo._seller).call {value: saleinfo._offerprice} ("");
			// 	}
			// 	else {revert("ERR() value does not meet price");}
			// } else { //Token
			// 	if ( IERC20( saleinfo._paymeansaddress).transferFrom( msg.sender , saleinfo._seller , saleinfo._offerprice) ){
			// 	}
			// 	else {revert("ERR() value does not meet price"); }
			// }
			feepayer(saleinfo._target_erc1155_contract, saleinfo._paymeansaddress, tokenid, msg.sender, saleinfo._seller, saleinfo._offerprice, "TRADE_FEE");


			IERC1155 ( saleinfo._target_erc1155_contract ).safeTransferFrom ( //Transfer NFT from Seller to Buyer
				saleinfo._seller
				, msg.sender
				, tokenid
				, saleinfo._amounttosell
				, "0x00"
			) ;
			return "UNCLAIMED";
		}
	}
	function payment(address _paymentaddress, address _from, address _to, uint256 _amount) internal {
		if(_paymentaddress == address(0)){
			//Native transfer
			payable(_to).call {value: _amount} ("");
		}else{
				//Token transfer
				if(_from ==address(this)){
					console.log("from: %s, to: %s", _from, _to);
					IERC20( _paymentaddress).transfer(_to , _amount);
				}else{
					IERC20( _paymentaddress).transferFrom( _from , _to , _amount);
				}
		}
	}

	function feepayer(
		address _target_erc1155_contract,
		address _paymentaddress,
		uint256 _tokenid,
		address _buyer,
		address _seller,
		uint256 _amounttopay,
		string memory _type
	) internal {
		uint256 remaining_amount = _amounttopay;
		uint256 admin_fee_rate = IAdmin_nft(_admincontract)._action_str_fees(_type);
		uint256 admin_fee_amount = remaining_amount * admin_fee_rate / 10000 ;
		address vault_contract = IAdmin_nft(_admincontract)._vault();
		uint256 author_royalty_rate = IERC1155(_target_erc1155_contract)._author_royalty(_tokenid);
		uint256 author_royalty_amount = _amounttopay * author_royalty_rate /10000;
		address author = IERC1155(_target_erc1155_contract)._author (_tokenid);
		require(remaining_amount>(admin_fee_amount + author_royalty_amount), "ERR() WRONG FEE TAKER");
		//ADMIN FEE
		if(admin_fee_amount>0 && IAdmin_nft(_admincontract)._action_str_fees_bool(_type)){
			if(vault_contract == address(0)){
				revert("ERR() INVALID VAULT ADDRESS");
			}
			payment(_paymentaddress, _buyer, vault_contract, admin_fee_amount);
			remaining_amount-=admin_fee_amount;
		}
		/* ROYALTY */
		if(author_royalty_amount>0 && author != msg.sender){
			payment(_paymentaddress, _buyer, author, author_royalty_amount);
			remaining_amount -= author_royalty_amount;
		}
		/*TRANSFER TO SELLER*/
		payment(_paymentaddress, _buyer, _seller, remaining_amount);
	}

	function settle (
		Signature memory _sig_done_delivery,
		 string memory _uuid
	) public {
		Sale_info memory saleinfo = _map_sale_info [ _uuid ];
		Pay_info memory payinfo = _map_pay_info [_uuid];
		if ( saleinfo._status  ) {}
		else {revert ("ERR() sale info not found"); }
		if ( payinfo._status  ){}
		else { revert("ERR() pay info not found");}
		address buyer = payinfo._buyer ;
		require(msg.sender == buyer || msg.sender == _contractowner, "Tangible Fixed:: Not a buyer");
		IERC1155( saleinfo._target_erc1155_contract ).safeTransferFrom ( address (this)
			, payinfo._buyer
			, payinfo._tokenid
			, saleinfo._amounttosell
			, "0x00"
		);
		//Return Token or price to seller
		feepayer(saleinfo._target_erc1155_contract, saleinfo._paymeansaddress, payinfo._tokenid, address(this), saleinfo._seller, saleinfo._offerprice, "TRADE_FEE");
		//makepayment(saleinfo._paymeansaddress, saleinfo._offerprice, saleinfo._seller);
		_map_pay_info[ _uuid]._status = false ;
		_map_sale_info[ _uuid]._status=false ;
	}


	function claim_issue (string memory _uuid, bool value)public{
		Sale_info memory saleinfo = _map_sale_info [ _uuid ];
		Pay_info memory payinfo = _map_pay_info [_uuid];
		require(payinfo._buyer == msg.sender, "FIXED ERR() ONLY BUYER CAN ACCESS");
		if(saleinfo._expiry + 7 days < block.timestamp){
			revert("FIXED ERR() CANNOT CLAIM ISSUE AFTER 7 days");
		}
		_map_uuid_issue[_uuid] = value;
	}

	function cancel_escrow ( string memory _uuid)public{
		Sale_info memory saleinfo = _map_sale_info[_uuid];
		Pay_info memory payinfo = _map_pay_info [_uuid];
		if(_map_uuid_issue[_uuid] == true){
			if(msg.sender == _map_sale_info[_uuid]._seller){
				IERC1155( saleinfo._target_erc1155_contract ).safeTransferFrom ( address (this)
				, saleinfo._seller
				, payinfo._tokenid
				, saleinfo._amounttosell
				, "0x00"
				);
				payment(saleinfo._paymeansaddress, address(this), saleinfo._seller, payinfo._amounttopay);
			}
		}
	}
	function set_admincontract(address __admincontract) public {
		_admincontract = __admincontract;
	}
	
}