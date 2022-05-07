
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./IVerify_signature.sol" ;
import "./IERC1155.sol";
import "./interface_sale_info.sol";
contract SuggestToSell is ERC1155MockReceiver , Sale_info , Ownable {
	mapping ( address => uint256 ) public _balances ;
//	mapping ( string => Offer_info ) public _map_offerid_Offer_info ;
	mapping ( string => Offer_info ) public _map_offer_info ;
	address public _owner ;
	address public _verify_signature_lib ;
	constructor ( address __verify_signature_lib ) {
		_verify_signature_lib = __verify_signature_lib ; //		_owner = msg.sender ;
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
//		, Signature memory off // not need it since cash 
		// 	address _target_erc1155_contract // 0
 		// , string memory _itemid // 1
		// , uint256 _amounttomint // 2
		// , uint256 _author_royalty // 3
		// , address _author // 4
		// , address _seller // 5
		// , address _buyer // 6
		// , uint256 _amounttobuy // 7
		// , uint256 _amounttopay // 8
		// , address _paymeansaddress // 9
		// , uint256 _expiry // 10
//		, string memory _uuid
	) public payable {
		/****** mint as usual */
		uint256 tokenid = IERC1155( mintinfo._target_erc1155_contract )._itemhash_tokenid ( mintinfo._itemid) ; // 9 //		require ( _amounttomint >= _amounttobuy , "ERR() amount invalid") ;
		if ( tokenid == 0 ){
			tokenid = IERC1155 ( mintinfo._target_erc1155_contract ).mint (
					mintinfo._author
				, mintinfo._itemid
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
			if ( IERC20( offerinfo._paymeansaddress ).transferFrom( msg.sender, address(this) , offerinfo._amounttopay ) ){}
			else {revert( "ERR() amount not met") ; }
		} //		_balances [ msg.sender ] += _amounttopay ;
		_map_offer_info [ _uuid ] = offerinfo ;
	}
/** 	function get_offer_info ( bytes memory _offerid ) public returns ( Offer_info memory ){		return _map_offerid_Offer_info [ _offerid ] ;	}
	function get_offer_info ( string memory _uuid ) public returns ( Offer_info memory ) {		return _map_offer_info [ _uuid ] ;	} */
	function initoffermap ( string memory _uuid ) internal {
		_map_offer_info [ _uuid ] = Offer_info (address(0) , address(0) , address(0) , "",address(0) , 0,0,0 ,false );
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
/** if ( Offer_info._paymeansaddress == address(0)){			payable (Offer_info._buyer).call { value : Offer_info._amounttopay } ("");		} 
		else {			IERC20( _paymeansaddress ).transfer ( Offer_info._buyer , Offer_info._amounttopay ) ;
		} */
//		_map_offer_info [ _uuid ] = Offer_info (address(0) , address(0) , address(0) , "",0,0,false );
		initoffermap ( _uuid ) ;
	}
	function settle_offer ( string memory _uuid ) public {
		Offer_info memory Offer_info = _map_offer_info [ _uuid ] ;
		if ( Offer_info._active ){}
		else {revert("ERR() invalid offer"); }
		if ( Offer_info._expiry > block.timestamp ){}
		else {			initoffermap( _uuid ); // this func has side effect of deleting offers that are supposed to have expired
		}
		uint256 tokenid = IERC1155( Offer_info._target_erc1155_contract )._itemhash ( Offer_info._itemid );
		IERC1155( Offer_info._target_erc1155_contract ).safeTransferFrom ( Offer_info._seller , Offer_info._buyer , tokenid , Offer_info._amounttobuy , "0x00" );
		makepayment ( Offer_info._paymeansaddress
			, Offer_info._amounttopay
			, Offer_info._seller
		) ;
		initoffermap( _uuid ) ;
	}
	modifier onlyowner ( address _address ) {
    require( _address == _owner , "ERR() not privileged");
    _;
  }
	function accept_offer ( string memory _uuid ) public {
		Offer_info offerinfo = _map_offer_info [ _uuid ] ;
		uint256 tokenid = IERC1155 ( offerinfo._target_erc1155_contract )._itemhash_tokenid ( offerinfo._itemid ) ;
		IERC1155 ( offerinfo._target_erc1155_contract ).safeTransferFrom ( 
				offerinfo._seller
			, address( this )
			, tokenid
			, offerinfo._amounttobuy
			, "0x00" 
		) ;
	}
	function settle ( 
		Signature memory _sig_done_delivery
		, address _signing_admin
		, string memory _uuid
	) public {
		if ( _signing_admins[ _signing_admin ] ){}
		else { revert ("ERR() signer invalid") ; }
		if ( verify_done_delivery_signature ( _uuid , _sig_done_delivery , _signing_admin ) ){}
		else {}
		/****** payments */
		Offer_info memory offerinfo = _map_offer_info [ _uuid ] ;
		if ( offerinfo._status ){}
		else {revert("ERR() offer not found") ; }
		payable ( offerinfo._seller ).call { value : offerinfo._amounttopay } ("");
		uint256 tokenid = IERC1155 ( offerinfo._target_erc1155_contract )._itemhash_tokenid ( offerinfo._itemid );
		IERC1155 ( offerinfo._target_erc1155_contract ).safeTransferFrom ( address(this)
			, offerinfo._buyer
			, tokenid
			, offerinfo._amounttobuy
			, "0x00"
		);
	}
	function withdraw_fund ( address _paymeansaddress 
		, uint256 _amount 
		, address _to
	) public onlyowner ( msg.sender ){
		makepayment ( _paymeansaddress , _amount , _to ) ;
	}

}
/** 	function mint_and_offer ( 예치금을 지불하여 고정가 구매를 리스팅합니다. 민팅이 되어있지 않을 경우, 첫 오퍼러가 민팅을 합니다. 인자에 uuid를 통해 오퍼 인스턴스를 생성합니다.)
Get_offer_info (mint_and_offer 를 통해 등록된 offer 인스턴스를 확인합니다.)
Cancel_offer ( 오퍼를 철회합니다. 예치금을 돌려받습니다.)
Settle_offer ( 토큰 소유자만 접근할 수 있으며, 오퍼 가격을 수락하여 판매를 진행합니다.)
Withdraw (컨트랙트에 보관 중이던 토큰을 관리자 지갑 주소로 인출합니다.)
*/
