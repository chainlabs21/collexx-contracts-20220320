pragma solidity ^0.8.0;
import "./Interfaces/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/IVerify-signature.sol" ;
import "./Interfaces/IERC1155.sol";
import "./Interfaces/ISaleInfo.sol";
import "./utils/Signing_admins.sol";
import "hardhat/console.sol";

import "./Interfaces/IAdmin_nft.sol";

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

contract SuggestToSell is ERC1155MockReceiver , SaleInfo , Ownable , Signing_admins {
	mapping ( address => uint256 ) public _balances ;
//	mapping ( string => Offer_info ) public _map_offerid_Offer_info ;
	mapping ( string => Offer_info ) public _map_offer_info ;
	mapping (string => bool) public _map_uuid_issue;
//	address public _owner ;
	address public _verify_signature_lib ;
	address public _admincontract;
	constructor ( address __verify_signature_lib, address __admincontract ) {
		_verify_signature_lib = __verify_signature_lib ; //		_owner = msg.sender ;
		_admincontract = __admincontract;
	}
	function set_with_admin_privilege ( string memory _uuid
		, Sale_info memory saleinfo
		, Offer_info memory offerinfo // payinfo
	 ) public {
		 require ( _signing_admins[ msg.sender ] , "ERR() not privileged" );		 
//		_map_sale_info [ _uuid ] = saleinfo ;
		_map_offer_info[ _uuid ] = offerinfo ;
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
	function mint_and_offer (
			Mint_info memory mintinfo
		, Signature memory mintsignature
		, Offer_info memory offerinfo
		, string memory _uuid // 11
	) public payable {
		/****** mint as usual */
		uint256 tokenid = IERC1155( mintinfo._target_erc1155_contract )._itemhash_tokenid ( mintinfo._itemid) ; // 9 //		require ( _amounttomint >= _amounttobuy , "ERR() amount invalid") ;
		if ( tokenid == 0 ){
			tokenid = IERC1155 ( mintinfo._target_erc1155_contract ).mint (
				mintinfo._author
				, mintinfo._itemid
				, mintinfo.revealedhash
				, mintinfo._amounttomint
				, mintinfo._author_royalty
				, mintinfo._decimals
				, "0x00"
			) ;
		} else {
		}

		if ( offerinfo._paymeansaddress == address( 0 ) ) {
			require( msg.value >= offerinfo._amounttopay , "ERR() amount not met");
		} else {
			IERC20(offerinfo._paymeansaddress).approve(address(this), offerinfo._amounttopay);
			if ( IERC20( offerinfo._paymeansaddress ).transferFrom( msg.sender, address(this) , offerinfo._amounttopay ) ){}
			else {revert( "ERR() amount not met") ; }
		}
		_map_offer_info [ _uuid ] = offerinfo ;
		_map_offer_info [_uuid]._tokenid = tokenid;
	}
	function initoffermap ( string memory _uuid ) internal {
		_map_offer_info [ _uuid ]._status = false ;
	}

	function cancel_offer ( string memory _uuid ) public {
		Offer_info memory offerinfo = _map_offer_info [ _uuid ] ;
		if ( offerinfo._status ){}
		else {revert("ERR() invalid offer id");}
		require ( msg.sender == offerinfo._buyer , "ERR() not privileged");
		makepayment( offerinfo._paymeansaddress
			, offerinfo._amounttopay
			, offerinfo._buyer
		) ;
		initoffermap ( _uuid ) ;
	}

	modifier onlyowner ( address _address ) {
    require( _address == _owner , "ERR() not privileged");
    _;
  }
	function accept_offer ( string memory _uuid, bool _isclaimed) public {
		Offer_info memory offerinfo = _map_offer_info [ _uuid ] ;
		uint256 tokenid = IERC1155 ( offerinfo._target_erc1155_contract )._itemhash_tokenid ( offerinfo._itemid ) ;
		require(offerinfo._expiry> block.timestamp, "OFFER ERR() EXPIRED OFFER");
		if(_isclaimed == true && IERC1155 ( offerinfo._target_erc1155_contract )._tokenid_isclaimed ( tokenid )){
			IERC1155 ( offerinfo._target_erc1155_contract ).safeTransferFrom ( 
					offerinfo._seller
				, address( this )
				, offerinfo._tokenid
				, offerinfo._amounttobuy
				, "0x00" 
			) ;
			//offerinfo._expiry = block.timestamp;
		} else{
			IERC1155 ( offerinfo._target_erc1155_contract ).safeTransferFrom ( 
					offerinfo._seller
				, offerinfo._buyer
				, offerinfo._tokenid
				, offerinfo._amounttobuy
				, "0x00" 
			) ;
			// if(offerinfo._paymeansaddress == address(0)){
			// 	payable ( offerinfo._seller ).transfer(offerinfo._amounttopay);
			// }else{
			// 	IERC20(offerinfo._paymeansaddress).transferFrom(address(this), offerinfo._seller, offerinfo._amounttopay);
			// 	console.log("%s is sending tokens to %s amount of %s", address(this), offerinfo._seller, offerinfo._amounttopay);
			// }
			feepayer(offerinfo._target_erc1155_contract, offerinfo._paymeansaddress, tokenid, offerinfo._buyer, offerinfo._seller, offerinfo._amounttopay, "TRADE_FEE");
		}
	}
	function settle ( 
		//Signature memory _sig_done_delivery
		//, address _signing_admin
		 string memory _uuid
		//, string[] memory _history
	) public {
		//if ( _signing_admins[ _signing_admin ] ){}
		//else { revert ("ERR() signer invalid") ; }
		//if ( verify_done_delivery_signature ( _uuid , _sig_done_delivery , _signing_admin ) ){}
		//else {}
		/****** payments */
		Offer_info memory offerinfo = _map_offer_info [ _uuid ] ;
		uint256 tokenid = IERC1155 ( offerinfo._target_erc1155_contract )._itemhash_tokenid ( offerinfo._itemid );
		console.log("TOKEN ID IS %s", offerinfo._tokenid);
		require(IERC1155(offerinfo._target_erc1155_contract).balanceOf(address(this), offerinfo._tokenid) == offerinfo._amounttobuy, "Not enought NFT balance");
		if ( offerinfo._status ){}
		else {revert("ERR() offer not found") ; }
		// if(offerinfo._paymeansaddress == address(0)){
		// 	payable ( offerinfo._seller ).transfer(offerinfo._amounttopay);
		// }else{
		// 	IERC20(offerinfo._paymeansaddress).transferFrom(address(this), offerinfo._seller, offerinfo._amounttopay);
		// 	console.log("%s is sending tokens to %s amount of %s", address(this), offerinfo._seller, offerinfo._amounttopay);
		// }
		feepayer(offerinfo._target_erc1155_contract, offerinfo._paymeansaddress, tokenid, offerinfo._buyer, offerinfo._seller, offerinfo._amounttopay, "TRADE_FEE");
		//uint256 tokenid = IERC1155 ( offerinfo._target_erc1155_contract )._itemhash_tokenid ( offerinfo._itemid );
		IERC1155 ( offerinfo._target_erc1155_contract ).safeTransferFrom ( address(this)
			, offerinfo._buyer
			, offerinfo._tokenid
			, offerinfo._amounttobuy
			, "0x00"
		);
		//makepayment(offerinfo._paymeansaddress, offerinfo._amounttopay, offerinfo._seller);
		initoffermap(_uuid);
	}


	function payment(address _paymentaddress, address _from, address _to, uint256 _amount) internal {
		if(_paymentaddress == address(0)){
			//Native transfer
			payable(_to).call {value: _amount} ("");
		}else{
				//Token transfer
				if(_from ==address(this)){
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
	

	function claim_issue (string memory _uuid, bool value)public{
		Offer_info memory offerinfo = _map_offer_info [ _uuid ];
		require(offerinfo._buyer == msg.sender, "OFFER ERR() ONLY BUYER CAN ACCESS");
		// if(saleinfo._expiry + 7 days < block.timestamp){
		// 	revert("FIXED ERR() CANNOT CLAIM ISSUE AFTER 7 days");
		// }
		_map_uuid_issue[_uuid] = value;
	}

	function cancel_escrow ( string memory _uuid)public{
		Offer_info memory offerinfo = _map_offer_info [ _uuid ];
		if(_map_uuid_issue[_uuid] == true){
			if(msg.sender == offerinfo._seller){
				IERC1155( offerinfo._target_erc1155_contract ).safeTransferFrom ( address (this)
				, offerinfo._seller
				, offerinfo._tokenid
				, offerinfo._amounttopay
				, "0x00"
				);
				payment(offerinfo._paymeansaddress, address(this), offerinfo._seller, offerinfo._amounttopay);
			}
		}
	}



	
	function withdraw_fund ( address _paymeansaddress 
		, uint256 _amount 
		, address _to
	) public onlyowner ( msg.sender ){
		makepayment ( _paymeansaddress , _amount , _to ) ;
	}

}
/** 	
function mint_and_offer ( 예치금을 지불하여 고정가 구매를 리스팅합니다. 민팅이 되어있지 않을 경우, 첫 오퍼러가 민팅을 합니다. 인자에 uuid를 통해 오퍼 인스턴스를 생성합니다.)
Get_offer_info (mint_and_offer 를 통해 등록된 offer 인스턴스를 확인합니다.)
Cancel_offer ( 오퍼를 철회합니다. 예치금을 돌려받습니다.)
Settle_offer ( 토큰 소유자만 접근할 수 있으며, 오퍼 가격을 수락하여 판매를 진행합니다.)
Withdraw (컨트랙트에 보관 중이던 토큰을 관리자 지갑 주소로 인출합니다.)
*/