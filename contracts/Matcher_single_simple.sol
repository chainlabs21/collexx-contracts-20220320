

pragma solidity ^0.8.0;
// import "./OwnableDelegateProxy.sol";
import "./Interfaces/IERC1155.sol" ;
// import "./openzeppelin/access/Ownable.sol" ; 
import "./Interfaces/IAdmin_nft.sol" ;
import "./Interfaces/IPayroll_fees.sol" ;
// import "./Utils.sol" ; XX
// import "./Interfaces/Interface_to_vault.sol" ;
// import "./OwnableDelegateProxy.sol";
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
contract Matcher_single_simple is // Ownable , Utils  ,
    Interface_to_vault
 {
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;
		return array;
	}
	enum PAY_REFERER_IMMEDIATE_OR_PERIODIC 	{
		__SKIPPER__
		, IMMEDIATE // right upon settlement
		, PERIODIC // monthly or sth periodic
	}
	enum PAY_AUTHOR_IMMEDIATE_OR_PERIODIC 	{
		__SKIPPER__
		, IMMEDIATE // right upon settlement
		, PERIODIC // monthly or sth
	}
	enum Fee_taker_role {
		REFERER
		, AUTHOR
	}

	address public _admincontract ;
	address public _user_proxy_registry ;
	address public _target_erc1155_contract_def ;
	address public _payroll ;
	address public _owner ; 
  string public _version ; 
	constructor (
			address __admincontract
		, address __user_proxy_registry
		, address __target_erc1155_contract_def
        , string memory __version
	) {
		_admincontract = __admincontract ;
		_user_proxy_registry = __user_proxy_registry ;
		_target_erc1155_contract_def = __target_erc1155_contract_def ;
		_owner = msg.sender ;
        _version = __version ;
	}
	struct Order {
		address matcher ;
		address maker ;
		address taker ;
		address seller ; 
		address buyer ;
		uint fee_bp_maker ;
		uint fee_bp_taker ;
		address vault ;
		uint side ;
//
		address asset_contract_bid ;
		uint [] asset_id_bid ;
		uint [] asset_amount_bid ;
		string [] asset_itemid_bid ;
//	
		address asset_contract_ask ; 
		uint [] asset_id_ask ;
		uint [] asset_amount_ask ;
		string [] asset_itemid_ask ;
// same as above, just array type so that 
		address [2] asset_contract ;
		uint [2] asset_id ;
		uint [2] asset_amount ;
//	
		address paymenttoken ;
		uint listing_starttime ;
		uint listing_endtime ;
		address referer ;
		uint256 referer_feerate ;
	}
  struct SignatureRsv {
    bytes32 r;/* r parameter */
    bytes32 s;/* s parameter */
    uint8 v;	/* v parameter */
  }
	struct Mint_data {
		string [] _itemhashes ;
		uint256 [] _amounts ; // degenerate to =1
		uint256 [] _author_royalty ;
		address _to ; // oughta be minter address in case buyer calls
	}
	function mint_and_match_single_simple (
		address _target_erc1155_contract // 0
		, string memory _itemid //1 //		, uint256 _tokenid // 2 ignored for now
		, uint256 _amounttomint // 2 
    , uint256 _author_royalty // 3 //        , uint256 _decimals // 5  //		, address _paymeans // 6
		, uint256 _amounttobuy // 4
		, uint256 _amounttopay // 5 //		, uint256 _pr ice // 7
		, address _author // 6

		, address _seller // 7 
		, address _to // 8 
		, address _referer // 9
	) public payable {
		require( _to != address(0) , "ERR() invalid beneficiary" );
		require( _seller != address(0) , "ERR() invalid seller" );				
		uint256 tokenid ;

		if ( ( tokenid = IERC1155( _target_erc1155_contract)._itemhash_tokenid( _itemid ) ) == 0 ){
			tokenid = IERC1155( _target_erc1155_contract ).mint (
			_author // _sell er
			, _itemid
			, _amounttomint // _am ount
			, _author_royalty
			, 0 // _decimals
			, "0x00"
			) ;
		} else {
		}
		/******* settlement */
		require( msg.value>= _amounttopay , "ERR() declared value inconsistent") ;
			uint256 remaining_amount = msg.value ; // order_buy.asset_amount_bid[0] ;
//			uint256 msg.value = msg.value; // order_buy.asset_amount_bid [ 0 ] ; // msg.value ;
	//		if( remaining_amount >= order_sell.asset_amount_ask [ 0]  ){} // asset_price[ 1 ]
		//	else { revert( "ERR() price not met" ); return; }
			/****  admin */
			uint256 admin_fee_rate = IAdmin_nft( _admincontract )._action_str_fees( "MATCH" ) ;
//			if(_admin_fee_rate > 0 ){	admin_fee_rate = _admin_fee_rate ; }
//			else {}
			uint256 admin_fee_amount = remaining_amount * admin_fee_rate / 10000 ;
            address vault_contract = IAdmin_nft( _admincontract )._vault() ;
			if (admin_fee_amount>0) {
				if (vault_contract == address(0) ){ revert("ERR() vault address invalid"); }
				payable( vault_contract ).call { value : admin_fee_amount } ( "" ) ; 
				emit DepositToVault(
					address(this)
					, admin_fee_amount
					, uint256(SEND_TYPES.ADMIN_FEE_SPOT) 
					, vault_contract
				);
				remaining_amount -= admin_fee_amount ;
			} else {}
			/**** referer */
//			uint referer_feerate = 100 ; // _referer_feerate ;
			if( true ){
//				address referer = _referer ; // order_buy.referer ;
				if(_referer == address(0)){}
				else {
//					uint pay_referer_when = IAdmin_nft( _admincontract)._PAY_REFERER_IMMEDIATE_OR_PERIODIC () ;
//					uint pay_referer_when = uint256(PAY_REFERER_IMMEDIATE_OR_PERIODIC.IMMEDIATE );
					uint256 referer_fee_amount = msg.value * 100 / 10000 ;
					if ( true   ) {
						payable( _referer ).call { value : referer_fee_amount} ( "" ) ;
						emit PaidFee (
							address(this)
							, referer_fee_amount
							, uint256(SEND_TYPES.REFERER_FEE_DEPOSIT) 
							, _referer
						);
					} /** else if ( pay_referer_when == uint256(PAY_REFERER_IMMEDIATE_OR_PERIODIC.PERIODIC)  )					{
						IPayroll_fees( _payroll ).increment_balance ( referer ,1, referer_fee_amount , uint256(Fee_taker_role.REFERER) ) ;
//						vault_contract.call { value : referer_fee_amount } ( "" ) ; 
						emit DepositToVault(
							address(this)
							, referer_fee_amount
							, uint256(SEND_TYPES.REFERER_FEE_DEPOSIT) 
							, vault_contract
						);
					} */
					remaining_amount -= referer_fee_amount ;
				}
			} else {}
			/***** royalty */
			if ( false ){	// need policy on royalty pay on bundle sell
			}
			else { // royalty resolution is certain
//				uint256 tokenid = _tokenid ;// IERC1155 (  ). ; // order_sell.asset_id_bid [ 0 ] ;
				uint author_royalty_rate = IERC1155 ( _target_erc1155_contract )._author_royalty ( tokenid ) ;
				if ( author_royalty_rate > 0 ) {
//					address author = IERC1155 ( _target_erc1155_contract )._author ( tokenid ) ;
					_author = IERC1155 ( _target_erc1155_contract )._author ( tokenid ) ;
					if (_author == address(0)){}
					else {
						uint256 author_royalty_amount = msg.value * author_royalty_rate / 10000 ;
//						uint pay_author_when = IAdmin_nft( _admincontract)._PAY_AUTHOR_IMMEDIATE_OR_PERIODIC() ;
						if ( true  ){ // 
							payable( _author ).call { value : author_royalty_amount } ( "" ) ;
						emit PaidFee (
							address(this)
							, author_royalty_amount
							, uint256(SEND_TYPES.AUTHOR_ROYALTY_DEPOSIT) 
							, _author
						);
						}
/**						else if (pay_author_when == uint256(PAY_AUTHOR_IMMEDIATE_OR_PERIODIC.PERIODIC)  )
						{	IPayroll_fees( _payroll ).increment_balance ( author ,1, author_royalty_amount , uint256(Fee_taker_role.AUTHOR) ) ;
							vault_contract.call { value : author_royalty_amount } ( "" ); 
							emit DepositToVault (
								address( this )
								, author_royalty_amount
								, uint256(SEND_TYPES.AUTHOR_ROYALTY_DEPOSIT) 
								, vault_contract
							) ;
						} */
						remaining_amount -= author_royalty_amount ;
					}
				}
				else {}
			}
			/***** remaining of sales proceeds */
			payable ( _seller ).call { value : remaining_amount } ("") ;

		/*******  */
		IERC1155( _target_erc1155_contract ).safeTransferFrom ( // Batch
		  _seller
      , _to
			, tokenid
      , _amounttobuy
      , "0x00"
		) ;
	}


	function only_owner_or_admin (address _address ) public returns ( bool )  {
		if ( _address == _owner || IAdmin_nft( _admincontract )._admins( _address ) ){return true ; }
		else {return false; } 
	}
	function set_payroll (address _address ) public {
		require(only_owner_or_admin(msg.sender) , "ERR() , not privileged" ) ; 
		_payroll = _address ;
	}

}

