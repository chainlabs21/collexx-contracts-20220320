
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./IVerify_signature.sol" ;
import "./IERC1155.sol";
import "./interface_sale_info.sol";

contract TangibleSpot is ERC1155MockReceiver , Sale_info , Ownable {
	address public _owner ;
//	address public _erc1155_contract_def ;
	mapping ( string => Sale_info ) public _map_sale_info ; // bytes32
	mapping ( string => Pay_info ) public _map_pay_info ; // bytes32
	address public _verify_signature_lib ;
	constructor ( address __verify_signature_lib ) { //		_owner = msg.sender ;
		_verify_signature_lib = __verify_signature_lib ;
	}
	function mint_and_escrow_to_buy (
			Mint_info mintinfo
		, Signature mintsignature
		, Sale_info saleinfo
		, Signature salesignature
		, Pay_info payinfo
	) public payable returns ( bool ) {
		uint256 tokenid = IERC1155 ( mintinfo._target_erc1155_contract)._itemhash_tokenid ( mintinfo._itemhash) ;
		if ( tokenid == 0 ){
			tokenid = IERC1155 ( mintinfo._target_erc1155_contract ).mint (
				mintinfo._author
				, mintinfo._itemid
				, mintinfo._amounttomint
				, mintinfo._author_royalty
				, mintinfo._decimals
				, "0x00"
			) ;
		}
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
		_map_sale_info[ saleinfo._uuid ] = saleinfo ;
		_map_pay_info [ saleinfo._uuid ] = Pay_info (
			msg.sender , saleinfo._itemid , saleinfo._tokenid , saleinfo._amounttosell , true , saleinfo._uuid
		); //		address _buyer ;		string _itemid ;		uint256 _tokenid ;		uint256 _amount ;		bool _status ;		string _uuid ;
		return true ;
	}
	function settle (
//	bytes32 _saleid
		Signature _sig_init_delivery
		, Signature _sig_done_delivery
		string memory _uuid
	) public {
		if ( ecrecover ( _sig_init_delivery , ) ) ;
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
	/* function pay_and_escrow (
		bytes32 _saleid
		, address _to
	) public payable returns ( bool ) {
		Sale_info saleinfo = _map_sale_info [ _saleid ];
		if ( saleinfo._status > 0 ) {	} 
		else {revert ("ERR() sale info not found"); }
		if ( msg.value >= saleinfo._offerprice ){}
		else {revert ("ERR() price not met");}
		if ( saleinfo._expiry >= block.timestamp ){ revert("ERR() sale expired"); }
		else {}
		Pay_info memory payinfo = Pay_info ( _to , saleinfo._itemid , saleinfo._tokenid , saleinfo._offerprice , true	) ;
		_map_pay_info [ _saleid ] = payinfo ;
	}
	function begin_sales_deposit_item ( 
		address _target_erc1155_contract
		, address _author
		, string memory _itemid
		, uint256 _amounttomint
		, uint256 _author_royalty
		, address _seller //		, uint256 _tokenid  // address
		, uint256 _amounttosell
		, uint256 _offerprice
		, uint _starting_time
		, uint _expiry
	) public {
		uint256 tokenid ;
		if ( (tokenid = IERC1155( _target_erc1155_contract)._itemhash_tokenid( _itemid)) ==0 ){
			tokenid = IERC1155 ( _target_erc1155_contract).mint ( 
			_author // _sell er
			, _itemid
			, _amounttomint // _am ount
			, _author_royalty
			, 0 // _decimals
			, "0x00"
			) ;
		} else {}
		IERC1155 ( _target_erc1155_contract ).safeTransferFrom (
			msg.sender
			, address ( this )
			, tokenid
			, _amounttosell
			, "0x00"
		) ;
		bytes32 saleid= get_Sale_info_id ( _holder // 0
			,  _target_contract  // 1
			,  _itemid // 2
			,  _amount  // 3
			,  _offerprice // 4
			,  _expiry // 5
		) ;
		_map_sale_info [ saleid ] = Sale_info (
			_target_erc1155_contract ,
			_author ,
			_itemid ,
			_tokenid ,
			_seller ,
		 _amounttosell ,
		 _starting_time ,
		 _expiry ,
		 _status );
	} */
}
/** 	function get_Sale_info_id (
			address _holder // 0
		, address _target_contract  // 1
		, string memory _itemid // 2
		, uint256 _amount  // 3
		, uint256 _offerprice // 4
		, uint256 _expiry // 5
	) public view returns ( bytes32 ){
		uint256 tokenid = IERC1155( _target_contract)._itemhash_tokenid ( _itemhash ) ;
		return keccak256(abi.encode ( _holder 
			, _target_contract 
			, _itemhash 
			, _amount 
			, _offerprice
			, _expiry ) 
		) ;
	}*/
