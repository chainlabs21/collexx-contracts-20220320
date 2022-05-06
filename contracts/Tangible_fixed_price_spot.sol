
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./IVerify_signature.sol" ;
import "./IERC1155.sol";
import "./interface_sale_info.sol";

contract TangibleSpot is ERC1155MockReceiver , Sale_info , Ownable {
	address public _owner ; //	address public _erc1155_contract_def ;
	mapping ( string => Sale_info ) public _map_sale_info ; // bytes32
	mapping ( string => Pay_info ) public _map_pay_info ; // bytes32
	address public _verify_signature_lib ;
	constructor ( address __verify_signature_lib ) { //		_owner = msg.sender ;
		_verify_signature_lib = __verify_signature_lib ;
	}
	function verify_done_delivery_signature ( string memory _uuid 
		, Signature _sig_done_delivery 
		, address _signing_admin
	) public {
		string data = encodePacked ( 'Done delivery' , _uuid );
		string datahash = keccak256 ( data ) ;
		address recoveredaddress = recoverSigner ( datahash , _sig_done_delivery._signature );
		return recoveredaddress == _signing_admin ;
	}
	function mint_and_escrow_to_buy (
			Mint_info mintinfo
		, Signature mintsignature
		, Sale_info saleinfo
		, Signature salesignature
		, Pay_info payinfo
	) public payable returns ( bool ) {
		/****** mint  as usual */
		uint256 tokenid = IERC1155 ( mintinfo._target_erc1155_contract)._itemhash_tokenid ( mintinfo._itemhash) ;
		if ( tokenid == 0 ) {
			tokenid = IERC1155 ( mintinfo._target_erc1155_contract ).mint (
				mintinfo._author
				, mintinfo._itemid
				, mintinfo._amounttomint
				, mintinfo._author_royalty
				, mintinfo._decimals
				, "0x00"
			) ;
		}
		/******* pull payment and item */
		if ( saleinfo._paymeansaddress == address(0) ) { 
			if (  msg.value >= saleinfo._offerprice){}
			else {revert("ERR() value does not meet price");}
		} else {
			if ( IERC20( saleinfo._paymeansaddress).transferFrom( msg.sender , address(this) , saleinfo._offerprice) ){}
			else {revert("ERR() value does not meet price"); }
		}
		IERC1155 ( _target_erc1155_contract ).safeTransferFrom (
			saleinfo._seller
			, address ( this )
			, tokenid
			, saleinfo._amounttosell
			, "0x00"
		) ;		
		if (_map_sale_info [ saleinfo._uuid ]._status ){revert("ERR() sale info already exists") ; } 
		else {}
		/****** register pay info */
		_map_sale_info[ saleinfo._uuid ] = saleinfo ;
		_map_pay_info [ saleinfo._uuid ] = Pay_info (
			msg.sender , saleinfo._itemid , saleinfo._tokenid , saleinfo._amounttosell , true , saleinfo._uuid
		); //		address _buyer ;		string _itemid ;		uint256 _tokenid ;		uint256 _amount ;		bool _status ;		string _uuid ;
		return true ;
	}
	function settle ( //	bytes32 _saleid
//			Signature _sig_init_delivery		, // trust admin then this is not needed , because there's sig done delivery
		Signature memory _sig_done_delivery
		, address _signing_admin
		, string memory _uuid
	) public {
		/***** verify sig */
		if ( _signing_admins[ _signing_admin ] ){}
		else { revert ("ERR() signer invalid") ; }
		if ( verify_done_delivery_signature ( _uuid , _sig_done_delivery ) ){}
		else {}
		/****** payments */
		Sale_info saleinfo = _map_sale_info [ _saleid ];
		if ( saleinfo._status  ) {}
		else {revert ("ERR() sale info not found"); }
		Pay_info payinfo = _map_pay_info [ _saleid ] ;
		if ( payinfo._status  ){}
		else { revert("ERR() pay info not found");}
		address seller = saleinfo._seller ;
		payable ( seller).call {value : saleinfo._offerprice } ("");
		address buyer = payinfo._buyer ;
		IERC1155( saleinfo._target_contract ).safeTransferFrom ( address (this)
			, payinfo._buyer
			, saleinfo._tokenid
			, saleinfo._amount
			, "0x00"
		);
		_map_pay_info[ _uuid]._status = false ;
		_map_sale_info[ _uuid]._status=false ;
	}
}
