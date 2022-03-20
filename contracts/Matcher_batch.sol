
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
}

contract Matcher_batch is // Ownable , Utils  ,
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
	constructor (
			address __admincontract
		, address __user_proxy_registry
		, address __target_erc1155_contract_def
	) {
		_admincontract = __admincontract ;
		_user_proxy_registry = __user_proxy_registry ;
		_target_erc1155_contract_def = __target_erc1155_contract_def ;
		_owner = msg.sender ;
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
		, string memory _itemid //1
		, uint256 _tokenid // 2 ignored for now
		, uint256 _amount // 3
    , uint256 _author_royalty // 4
    , uint256 _decimals // 5 
		, address _paymeans // 6
		, uint256 _price // 7
		, address _seller // 8 
		, address _to // 9
	) public payable {
		require( _to != address(0) , "ERR() invalid beneficiary" );
		require( _seller != address(0) , "ERR() invalid seller" );				
		uint256 tokenid ;
		if ( ( tokenid = IERC1155( _target_erc1155_contract)._itemhash_tokenid( _itemid ) ) == 0 ){
			tokenid = IERC1155( _target_erc1155_contract ).mint (
				_to
				, _itemid
				, _amount
                , _author_royalty
                , _decimals
				, "0x00"
			) ;
		} else {
		}
		payable ( _seller ).call {value : msg.value }("") ;
		IERC1155( _target_erc1155_contract ).safeTransferFrom ( // Batch
		    _seller
            , _to
            , tokenid
            , _amount
            , "0x00"
		) ;
		}
	//	address vault_contract = IAdmin_nft( _admincontract )._vault() ;
//		payable ( vault_contract ).call {value : msg.value }("") ;
/** 		
		function mint (
			address _to, //	beneficiary //		uint256 id,
			string memory _itemhash ,
			uint256 amount,
			uint256 __author_royalty ,
			uint256 __decimals ,
			bytes memory data
		) public override returns ( uint256 ) {

emit DepositToVault (
			address(this)
			, admin_fee_amount
			, uint256(SEND_TYPES.ADMIN_FEE_SPOT) 
			, vault_contract
		); */
	
	/**	function mint (
		address to, //		uint256 id,
		string memory _itemhash ,
		uint256 amount,
		bytes memory data
	) external ;
 */
	function mint_and_match_single (
		address _target_erc1155_contract //		, address _to // beneficiary
		, Order memory order_buy // due to the construction of this method ..
		, SignatureRsv memory signature_buy
		, Order memory order_sell
		, SignatureRsv memory signature_sell	
    , Mint_data memory _mint_data	
	) public payable  { // returns ( bool )
		require( _mint_data._to != address(0) , "ERR() invalid beneficiary" );
		if( order_sell.paymenttoken == address(0) ){
			if( order_sell.asset_amount_ask[ 0 ] <= msg.value ) {}
			else {revert("ERR() price not met"); return ;}
		} else {} // token pay not supported yet
		uint256 [] memory tokenids ;
		if ( IERC1155( _target_erc1155_contract )._itemhash_tokenid( _mint_data._itemhashes[0] ) == 0){ 
			tokenids = IERC1155( _target_erc1155_contract ).mintBatch (
			_mint_data._to
			,	_mint_data._itemhashes
			, _mint_data._amounts
			, _mint_data._author_royalty
			, ""			) ;
		}
		else {			tokenids[0] = IERC1155( _target_erc1155_contract )._itemhash_tokenid( _mint_data._itemhashes[0] );
		}
		require (can_match_order( order_buy , order_sell ), "ERR() cannot match orders" );
		uint256 admin_fee_rate = IAdmin_nft( _admincontract)._action_str_fees ("MINT_AND_MATCH_SINGLE") ;
		atomicMatch ( order_buy
			, signature_buy
			, order_sell
			, signature_sell
			, admin_fee_rate
		) ;
	}

	function can_match_order (Order memory order_buy , Order memory order_sell )
		public		view returns ( bool )
	{	/**  if( order_buy.asset_contract[0] == order_sell.asset_contract[1]){} else {return false; }
		if( order_buy.asset_contract[1] == order_sell.asset_contract[0]){} else {return false; }
		if( order_buy.asset_amount[0] 	== order_sell.asset_amount[1]){} else {return false; }
		if( order_buy.asset_amount[1] 	== order_sell.asset_amount[0]){} else {return false; }
		if( order_buy.asset_id[0] 			== order_sell.asset_id[1]){} else {return false; }
		if( order_buy.asset_id[1] 			== order_sell.asset_id[0]){} else {return false; } */
		if( order_buy.asset_contract_bid == order_sell.asset_contract_ask ){} else {return false; }
		if( order_buy.asset_contract_ask == order_sell.asset_contract_bid ){} else {return false; }
		if( order_buy.asset_amount_bid[0] 	== order_sell.asset_amount_ask[0] ){} else {return false; }
		if( order_buy.asset_amount_ask[0] 	== order_sell.asset_amount_bid[0] ){} else {return false; }
		if( order_buy.asset_id_bid[0] 			== order_sell.asset_id_ask[0] ){} else {return false; }
		if( order_buy.asset_id_ask[0]			== order_sell.asset_id_bid[0] ){} else {return false; }
		uint timestamp = block.timestamp ;
		if ( timestamp >= order_buy.listing_starttime){} else {return false; }
		if ( timestamp >= order_sell.listing_starttime){} else {return false; }
		if ( timestamp <= order_buy.listing_endtime  ){} else {return false; }
		if ( timestamp <= order_sell.listing_endtime  ){} else {return false; }
		return true;		
	} /**	+ exchange */
	function atomicMatch (
			Order memory order_buy
		, SignatureRsv memory signature_buy
		, Order memory order_sell
		, SignatureRsv memory signature_sell	
		, uint256 _admin_fee_rate
	) public payable {
//		require ( can_match_order ( order_buy , order_sell ) , "ERR() orders do not match" );
		address paymenttoken = order_sell.paymenttoken ; // symmetric
		/*** pay out , settlement */
		if( paymenttoken == address(0)){ // eth/klaytn
//			uint256 remaining_amount = msg.value  ;
			uint256 remaining_amount = order_buy.asset_amount_bid[0] ;
			uint256 bidamount = order_buy.asset_amount_bid [ 0 ] ; // msg.value ;
			if( remaining_amount >= order_sell.asset_amount_ask [ 0]  ){} // asset_price[ 1 ]
			else { revert( "ERR() price not met" ); return; }
			/****  admin */
			uint256 admin_fee_rate = IAdmin_nft( _admincontract )._action_str_fees( "MATCH" ) ;
			if(_admin_fee_rate > 0 ){	admin_fee_rate = _admin_fee_rate ; }
			else {}
			uint256 admin_fee_amount = remaining_amount * admin_fee_rate / 10000 ;
			address vault_contract = IAdmin_nft( _admincontract )._vault() ;
			if (vault_contract == address(0) ){ revert("ERR() vault address invalid"); }
			payable( vault_contract ).call { value : admin_fee_amount } ( "") ; 
			emit DepositToVault(
				address(this)
				, admin_fee_amount
				, uint256(SEND_TYPES.ADMIN_FEE_SPOT) 
				, vault_contract
			);
			remaining_amount -= admin_fee_amount ;
			/**** referer */
			uint referer_feerate = order_sell.referer_feerate ;
			if(referer_feerate>0){
				address referer = order_buy.referer ;
				if(referer == address(0)){}
				else {
					uint pay_referer_when = IAdmin_nft( _admincontract)._PAY_REFERER_IMMEDIATE_OR_PERIODIC () ;
					uint256 referer_fee_amount = bidamount * referer_feerate / 10000 ;
					if ( pay_referer_when == uint256(PAY_REFERER_IMMEDIATE_OR_PERIODIC.IMMEDIATE)  ) {
						payable( referer ).call { value : referer_fee_amount} ( "" ) ;
					} else if ( pay_referer_when == uint256(PAY_REFERER_IMMEDIATE_OR_PERIODIC.PERIODIC)  )
					{	IPayroll_fees( _payroll ).increment_balance ( referer ,1, referer_fee_amount , uint256(Fee_taker_role.REFERER) ) ;
						vault_contract.call { value : referer_fee_amount } ( "" ) ; 
						emit DepositToVault(
							address(this)
							, referer_fee_amount
							, uint256(SEND_TYPES.REFERER_FEE_DEPOSIT) 
							, vault_contract
						);
					}
					remaining_amount -= referer_fee_amount ;
				}
			} else {}
			/***** royalty */
			if ( order_sell.asset_id_bid.length > 1 ){	// need policy on royalty pay on bundle sell
			}
			else { // royalty resolution is certain
				uint256 tokenid = order_sell.asset_id_bid [ 0 ] ;				
				uint author_royalty_rate = IERC1155 ( order_sell.asset_contract_bid )._author_royalty ( tokenid ) ;
				if ( author_royalty_rate > 0 ) {
					address author = IERC1155 ( order_sell.asset_contract_bid )._author ( tokenid ) ;
					if (author == address(0)){}
					else {
						uint256 author_royalty_amount = bidamount * author_royalty_rate / 10000 ;
						uint pay_author_when = IAdmin_nft( _admincontract)._PAY_AUTHOR_IMMEDIATE_OR_PERIODIC() ;
						if ( pay_author_when == uint256(PAY_AUTHOR_IMMEDIATE_OR_PERIODIC.IMMEDIATE )  ){
							payable( author ).call { value : author_royalty_amount } ( "" ) ;
						}
						else if (pay_author_when == uint256(PAY_AUTHOR_IMMEDIATE_OR_PERIODIC.PERIODIC)  )
						{	IPayroll_fees( _payroll ).increment_balance ( author ,1, author_royalty_amount , uint256(Fee_taker_role.AUTHOR) ) ;
							vault_contract.call { value : author_royalty_amount } ( "" ); 
							emit DepositToVault (
								address( this )
								, author_royalty_amount
								, uint256(SEND_TYPES.AUTHOR_ROYALTY_DEPOSIT) 
								, vault_contract
							) ;
						}
						remaining_amount -= author_royalty_amount ;
					}
				}
				else {}
			}
			/***** remaining of sales proceeds */
			payable ( order_sell.seller ).call { value : remaining_amount } ("") ;
		} else {} // token not supported yet
		// 		
		IERC1155( order_sell.asset_contract_bid ).safeBatchTransferFrom ( order_sell.seller
			, order_buy.buyer
			, order_sell.asset_id_bid //_asSingletonArray( 
			,  order_sell.asset_amount_bid // _asSingletonArray(
            , "0x00"
		) ; //				
	} // end function atomicMatch
/**      function safeBatchTransferFrom( address from
	, address to
	, uint256[] memory ids
	, uint256[] memory amounts
	, bytes memory data    ) public virtual override {	
	*/
	function only_owner_or_admin (address _address ) public returns ( bool )  {
		if ( _address == _owner || IAdmin_nft( _admincontract )._admins( _address ) ){return true ; }
		else {return false; } 
	}
	function set_payroll (address _address ) public {
		require(only_owner_or_admin(msg.sender) , "ERR() , not privileged" ) ; 
		_payroll = _address ;
	}

}

/**  proxy inheritance
Proxy , OwnedUpgradeabilityStorage
OwnedUpgradeabilityProxy ( <= Proxy, OwnedUpgradeabilityStorage )
OwnableDelegateProxy ( <= OwnedUpgradeabilityProxy )
AuthenticatedProxy proxy = AuthenticatedProxy(delegateProxy);
proxy.proxy(sell.target
					, sell.howToCall
					, sell.calldata  )
*/
//        function register_proxy () public returns (address address_ )
/**	funct ion mint_and_match_batch (
	function can_match_order (
		Order memory order_buy
		, Order memory order_sell )
	function atomicMatch (
	} // end function atomicMatch
      function safeBatchTransferFrom( address from
	function only_owner_or_admin (address _address ) {
	function set_payr oll (address _address ) {
		*/
// contract Utils {
/** library Utils {
	function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
			uint256[] memory array = new uint256[](1);
			array[0] = element;
			return array;
	}
} */
/** contract ProxyRegistry {
	mapping ( address => address) proxies;
  address public delegateProxyImplementation;
	function register_proxy () public returns (address address_ ) 
	{
		OwnableDelegateProxy delegateProxy = new OwnableDelegateProxy (
			msg.sender
			, delegateProxyImplementation;
			, abi.encodeWithSignature("initialize(address,address)"
				, msg.sender
				, address(this)
			)
		) ;
		proxies [ msg.sender ]  = address( delegateProxy );
		return new address( delegateProxy);
	}
} */
