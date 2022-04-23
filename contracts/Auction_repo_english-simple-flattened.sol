
pragma solidity ^0.8.0;
/**  import "./Interfaces/IProxyRegistry.sol" ; // XX
import "./Interfaces/IERC1155.sol" ; // XX
import "./ERC1155MockReceiver.sol"; // XX
import "./Interfaces/IPayroll_fees.sol" ; // XX
import "./Interfaces/Interface_to_vault.sol" ; // XX
*/
// import "./Interfaces/IAdmin_nft.sol";
interface IERC1155  { // is IERC165
	function _acting_contracts ( address _address ) external view returns ( bool _status) ;
	function set_acting_contracts( address _address , bool _status ) external ;

	function safeTransferFrom (
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external ;
	function safeBatchTransferFrom (
		address from,
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external;
	function mint (
		address to, //		uint256 id,
		string memory _itemhash ,
		uint256 amount,
		uint256 __author_royalty ,
		uint256 __decimals ,
		bytes memory data
	) external returns ( uint256 );
	function mintBatch (
		address to, //			uint256[] memory ids,
		string [] memory _itemhashes ,
		uint256[] memory amounts,
		uint256 [] memory __author_royalty ,
		bytes memory data
	) external returns ( uint256 [] memory ) ;
	function burn (
		address from,
		uint256 id,
		uint256 amount
	)	external ;
	function burnBatch (
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) external ;
  event TransferSingle (
			address indexed operator
		, address indexed from
		, address indexed to
		, uint256 id
		, uint256 value ); /**     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.     */
  event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] values
  );
	function _itemhash_tokenid ( string memory  ) external view returns (uint256 ) ; // content id mapping ( string => uint256 ) public
	function _tokenid_itemhash ( uint256 ) external view returns ( string memory ) ; // mapping (uint256 => string ) public

	function _token_id_global () external view returns ( uint256 ) ;
	function _author_royalty ( uint256 ) external view  returns ( uint );
	event ApprovalForAll(address indexed account, address indexed operator, bool approved); /**     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to     * `approved`.     */
	event URI(string value, uint256 indexed id);     /**     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.     *     * If an {URI} ev ent was emitted for `id`, the standard     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value     * returned by {IERC1155MetadataURI-uri}.     */    
  function balanceOf(address account, uint256 id) external view returns (uint256); /**     * @dev Returns the amount of tokens of token type `id` owned by `account`.     *     * Requirements:     *     * - `account` cannot be the zero address.     */    
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)        external        view        returns (uint256[] memory); /**     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.     *     * Requirements:     *     * - `accounts` and `ids` must have the same length.     */    
  function setApprovalForAll(address operator, bool approved) external; /**     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,     *     * Emits an {ApprovalForAll} ev ent.     *     * Requirements:     *     * - `operator` cannot be the caller.     */    
  function isApprovedForAll(address account, address operator) external view returns (bool);		/**     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.     *     * See {setApprovalForAll}.     */
	function _author ( uint256 ) external view returns ( address ) ;
//	mapping ( uint256=> address ) public _author ; // do struct if more than two
}
interface IAdmin_nft {
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
	function _payroll_fees_contract () external view returns ( address );
	function set_payroll_fees_contract ( address _address) external ;

	function _owner () external view returns ( address ) ;

	function ADMIN_FEE_RATE_DEF () external view returns ( uint256 ) ;
	function _admins (address _address) external view returns (bool) ;
	function set_admin ( address _address , bool _status ) external ;

	function set_action_str_fee ( string memory _action_str ) external ;
	function _action_str_fees ( string memory _action_str ) external view returns ( uint ) ;

//	function _author_royalty_max () external returns (uint256 );
//	function _referer_fee_max () external returns (uint256) ;

	function _vault () external view returns (address );
	function set_vault ( address _address ) external ;

//	function _min_balance_required_author_royalty () external returns ( uint256 ) ;
//	function _min_balance_required_referer_fee () external returns (uint256 );

	function _PAY_REFERER_IMMEDIATE_OR_PERIODIC () external view returns ( uint ) ; 
	function set_PAY_REFERER_IMMEDIATE_OR_PERIODIC ( uint _choice ) external ; 

	function _PAY_AUTHOR_IMMEDIATE_OR_PERIODIC () external view returns ( uint ) ;
	function set_PAY_AUTHOR_IMMEDIATE_OR_PERIODIC ( uint _choice ) external ;

	function _last_minute_call_timewindow ( ) external view  returns ( uint256 );
	function set_last_minute_call_timewindow ( uint256 __timewindow_length ) external ;

	function _timelength_to_extend_last_minute_call_by () external view  returns ( uint256 )  ; // 10 min * 60 sec
	function set_timelength_to_extend_last_minute_call_by (uint256 ) external ; // 10 min * 60 sec

	function _allow_duplicate_datahash ( ) external view returns ( bool );
	function set_allow_duplicate_datahash ( bool _allow ) external ;

	function _use_user_black_whitelist_or_none () external view returns ( uint256 _use_list ) ;
	function set_use_user_black_whitelist_or_none ( uint256 _use_list ) external ;

	function _user_black_white_list_registry () external view returns ( address ) ;
	function set_user_black_white_list_registry ( address _address ) external ;	

	function _author_royalty_max ( ) external view returns ( uint _maxvalue );
	function set_author_royalty_max (uint _maxvalue ) external ;

	function _referer_fee_max () external view  returns ( uint _maxvalue  );
	function set_referer_fee_max ( uint _maxvalue ) external ;

	function _min_balance_required_author_royalty () external view returns (uint _min_required ) ;
	function set_min_balance_required_author_royalty (uint _min_required ) external ;

	function _min_balance_required_referer_fee ( ) external view returns (uint _min_required) ;
	function set_min_balance_required_referer_fee (uint _min_required ) external ;

	function _user_proxy_registry ()	 external view returns ( address _address ) ;
	function set_user_proxy_registry ( address _address ) external ;
}
interface IPayroll_fees { 
	function _admin_contract () external  returns (address) ;	
	function _owner () external returns ( address ) ;
	function increment_balance (address _address ,
		uint256 incdec,
	 uint256 _addend , uint _taker_role ) external  ;
	function payout ( address [] memory _addresses , address __vault ) external ;
	function set_admin_contract (address _address) external ;
	function set_accessor (address _address , bool _status ) external ;
	function set_vault ( address _address ) external ;
}
// pragma solidity ^0.5.0;
// import "./Common.sol";
// import "./Interfaces/IERC1155TokenReceiver.sol";
contract CommonConstants {
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

contract Auction_repo_english_simple is ERC1155MockReceiver // , Interface_to_vault
{
	enum PAY_REFERER_IMMEDIATE_OR_PERIODIC {
		__SKIPPER__
		, IMMEDIATE // right upon settlement
		, PERIODIC // monthly or sth periodic
	}
	enum PAY_AUTHOR_IMMEDIATE_OR_PERIODIC {
		__SKIPPER__
		, IMMEDIATE // right upon settlement
		, PERIODIC // monthly or sth
	}
	enum Fee_taker_role {
		REFERER
		, AUTHOR
	}
	address public _user_proxy_registry ;
	address public _admin_contract ;
	address public _erc1155_contract ; // this one : where to use
	address public _payroll ;
	address _owner ;
//	mapping (address => mapping(uint256 => bool ) ) _is_contract_i tem_onauction ;
//	event Deposit ToVault () ;
	mapping (string => uint ) ADMIN_FEE_RATES_DEF ;
	uint ADMIN_FEE_RATE_DEF = 250;
	struct Auction_info_batch {
		address _opener ; // 0 // the one who opened this auction on behalf of _holder
		address _holder ; // 1 // assets owner/holder
		address _target_contract ; // 2
		uint256 [] _target_item_ids ; // 3  address
		uint256 [] _amounts ; // 4
		uint _status ; // 5 // 0 : inactive/close , 1 : active , 2:?
		address _paymenttoken ; // 6
		uint256 _offerprice ;	 // 7
		uint _starting_time ;  // 8
		uint _expiry ; // 9
		uint _referer_feerate ; // 10
	}
	enum Auction_instance_status {
		__SKIPPER__
		, Active,
        Closed
	}
	struct Bid_info {
		address _bidder ;
		uint256 _amount ;
		uint _bidtime ;
		bool _active ;
		uint _bidcount ;
		address _referer ;
	}
// mapping (address => mapping(uint256 => Auction_info_single ) ) _auction_info_single ;
//	mapping (address => mapping(uint256 => Auction_info_batch  ) ) _batch_hashid_auction_info ;
	mapping ( bytes32 => Auction_info_batch ) public _batch_hashid_auction_info ;
	mapping ( bytes32 => bool ) public _is_batch_hashid_onauction ;
	mapping ( bytes32 => Bid_info ) public _batch_hashid_bidinfo ;
	string public _version ;
	constructor ( address __user_proxy_registry
		, address __admin_contract
		, address __erc1155_contract
		, string memory __version
	) {
		_owner = msg.sender ;
		_admin_contract = __admin_contract ;
		_user_proxy_registry = __user_proxy_registry ;
		_erc1155_contract = __erc1155_contract;
		ADMIN_FEE_RATES_DEF["CLOSE_AUCTION"] = ADMIN_FEE_RATE_DEF ;
		_version = __version ;
	}
	function get_batch_hashid ( 
			address _holder // 0
		, address _target_contract  // 1
		, string memory _itemhash // 2
		, uint256 _amount  // 3
		, uint256 _offerprice // 4
		, uint256 _expiry // 5
	) public view returns ( bytes32 ) {
		uint256 tokenid = IERC1155( _target_contract)._itemhash_tokenid ( _itemhash ) ;
		return keccak256(abi.encode ( _holder 
			, _target_contract 
			, _itemhash 
			, _amount 
			, _offerprice
			, _expiry ) 
		) ;
	}
	function get_batch_hashid ( address _holder  // polymo
		, address _target_contract 
		, uint256 _target_item_id
		, uint256 _amount 
		, uint256 _offerprice
		, uint256 _expiry
		) public pure returns ( bytes32 ) { 
		return keccak256(abi.encode ( _holder 
			, _target_contract 
			, _target_item_id 
			, _amount 
			, _offerprice
			, _expiry ) 
		) ;
	}
	function get_batch_hashid ( address _holder 
		, address _target_contract 
		, uint256 [] memory _target_item_ids 
		, uint [] memory _amounts
		 ) public pure returns ( bytes32 ) { 
		return keccak256(abi.encode ( _holder ,_target_contract , _target_item_ids , _amounts ) ) ;
	}
	function validate_auction_open (
		address _target_contract
//		, address _user_proxy_registry
		, address _opener
		, address _holder
		, uint256 [] memory _target_item_ids // address
		, uint256 [] memory _amounts
	) public view returns ( bool ) {
		uint256 count = _target_item_ids.length ;
		require( count == _amounts.length , "ERR() arg lengths do not match" );
		for (uint256 i=0 ; i<count ; i++){
			require( IERC1155(_target_contract ).balanceOf( _holder , _target_item_ids[i] ) >= _amounts[i] , "ERR() balance not enough" );			
			// function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
		}
		return true ;
	}
  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;
		return array;
  }
  function _bid ( address _target_contract
		, bytes32 _batch_hashid 
		, address _paymenttoken
		, uint256 _amount
		, address _to // beneficiary so that call syntax/context is more flexible
		, address _referer
//		, uint256 _bidamount
	) internal  returns ( uint256 ) {
//		bytes32 batch_hashid = get_batc h_hashid( _holder , _target_contract , _target_contract ,  );
		require( _is_batch_hashid_onauction[_batch_hashid] , "ERR() batch not on sale" ); // _is_contract_item_onauction
		Auction_info_batch memory auction_info = _batch_hashid_auction_info [ _batch_hashid ] ;
		require( _amount >= auction_info._offerprice , "ERR() price not met" );
		require( auction_info._expiry > block.timestamp , "ERR() sale expired");
		require( auction_info._status >0 , "ERR() invalid auction id" );
		Bid_info memory bid_info 					= _batch_hashid_bidinfo [ _batch_hashid ] ;
		uint256 bidcount = 0 ;
		if( bid_info._active ) { // previous bid exists
			if( _amount > bid_info._amount ){}
			else {revert("ERR() amount less than previous bid" ); return 0 ;}
			bidcount = bid_info._bidcount ;
			payable( bid_info._bidder ).call { value : bid_info._amount } (""); // refund
		} else { // this bid is first bid
		}
		if (auction_info._paymenttoken == address(0)){ // native eth/klaytn 
//			if( _bidamount >= _amount){}
	//		else {revert("ERR() price not met"); }
		}
		else { } // token
		_batch_hashid_bidinfo [ _batch_hashid ] = Bid_info ( _to 
			, _amount
			, block.timestamp
			, true // _active
			, 1 + bidcount
			, _referer
		) ;
		// extend_expiry_on_bid ( _batch_hashid , block.timestamp ) ;
        return 1;
//		return extend_expiry_on_bid ( auction_info , _batch_hashid , block.timestamp ) ;
	} // end function _bid

	event OpenedAuction (
		address _holder // 0
		, address _target_contract  // 1
		, string _itemhash // 2
		, uint256 _amount  // 3
		, uint256 _offerprice // 4
		, uint256 _expiry // 5
		, bytes32 batch_hashid
	) ;
	function mint_begin_simple_and_bid (
		address _target_contract
		, address _author
		, string memory _itemid
		, uint256 _amounttomint
		, uint256 _author_royalty

		, address _seller //		, uint256 _tokenid  // address
		, uint256 _amounttoauction
		, uint256 _offerprice
		, uint _starting_time
		, uint _expiry
//		, uint _referer_feerate
		, uint256 _bidprice
//		, address _referer
//		, address _to
//		, bytes calldata _calldata
	) public payable returns ( bool ) {
		uint256 tokenid;
		bytes32 batch_hashid ;
//		if ( _tokenid ==0 ){
			if ( ( tokenid = IERC1155( _target_contract)._itemhash_tokenid( _itemid ) ) == 0 )			{
				tokenid = IERC1155( _target_contract ).mint (
				_author
				, _itemid
				, _amounttomint
				, _author_royalty
        , 0 // _decimals
				, "0x00"
				 ) ;
			}
	//	} /** 		else {			require( _tokenid < IERC1155(_target_contract)._token_id_global() ,"ERR() invalid token id");			tokenid = _tokenid ;		}*/
		batch_hashid = get_batch_hashid ( _seller // 0
			, _target_contract  // 1
			, tokenid  // 2
			, _amounttoauction // 3
			, _offerprice // 4
			, _expiry ) ; // 5
		require( msg.value >= _bidprice , "ERR() declared value inconsistent") ;
		if ( _is_batch_hashid_onauction[ batch_hashid ] ){ // mint + register done
		}	 else {
			require ( validate_auction_open (
					_target_contract 
				, msg.sender 
				, _seller // _ho lder 
				, _asSingletonArray( tokenid )
				, _asSingletonArray( _amounttoauction )
			) , "ERR() req invalid") ;
			if ( true ){ IERC1155 ( _target_contract ).safeTransferFrom ( _seller // _ho lder 
				, address(this)
				, tokenid
				, _amounttoauction
				, "0x00"
			); }
			_batch_hashid_auction_info [ batch_hashid ] = Auction_info_batch (
						msg.sender // 0
				, _seller // 1 _hol der
				, _target_contract // 2
				, _asSingletonArray( tokenid )  // 3
				, _asSingletonArray( _amounttoauction ) // 4
				, uint256( Auction_instance_status.Active )  // 5
				, address(0)  // 6 // _paymenttoken
				, _offerprice // 7
				, _starting_time // 8
				, _expiry // 9
				, 0  // 10 // _referer_feerate
			) ;
			_is_batch_hashid_onauction [ batch_hashid ] = true ;
/**			emit OpenedAuction (
				_seller // 0
				,  _target_contract  // 1
				,  _itemhash // 2
				,  _amount  // 3
				,  _offerprice // 4
				,  _expiry // 5
				,  batch_hashid
			) ;*/
		}
		_bid ( _target_contract
			, batch_hashid 
			, address(0)
			, _bidprice
			, msg.sender // _to // beneficiary so that call syntax/context is more flexible
			, address(0 )// _referer
		);
	}

	function extend_expiry_on_bid ( // returns updated or un-updated expiry
		Auction_info_batch memory auction_info
		, bytes32 _batch_hashid
		, uint256 _timeepoch
	) internal returns ( uint256 ) {
		uint256 expiry = auction_info._expiry ;
		uint256 timewindow_inesc = IAdmin_nft( _admin_contract )._last_minute_call_timewindow() ;
		if( _timeepoch < expiry && _timeepoch >= expiry - timewindow_inesc ){ // should strictly be in this interval , still need to check whether to include equality 
			uint256 time_to_extend = IAdmin_nft ( _admin_contract )._timelength_to_extend_last_minute_call_by () ;
			auction_info._expiry += expiry + time_to_extend ; // auction_info._expiry += _timeepoch + time_to_extend ;
			_batch_hashid_auction_info [ _batch_hashid ] = auction_info ;
			return auction_info._expiry ;
		}
		return expiry ;
	} // end

	function reinit_auction_data ( bytes32 _batch_hashid ) internal{	
        uint256 [] memory emptyarray ;
        _batch_hashid_auction_info[ _batch_hashid ] = Auction_info_batch (
				address(0)
			, address(0)
			, address(0)
//			, (uint256) []
//			, (uint256) []
			,  emptyarray //  [ ]
			,  emptyarray // new uint256 []
			, 0
			, address(0)
			, 0
			, 0
			, 0
			, 0
		) ;
		_batch_hashid_bidinfo [ _batch_hashid ] = Bid_info (
			address(0)
			, 0
			, 0
			, false
			, 0
            , address(0)
		) ;
		_is_batch_hashid_onauction[ _batch_hashid ] = false ;
	}
	function settle_auction ( bytes32 _batch_hashid	) public {
// access restriction is none/minimal here so that any caller who can take corresponding gas fee could call
		Auction_info_batch memory auction_info = _batch_hashid_auction_info [ _batch_hashid ] ;
		if ( IAdmin_nft( _erc1155_contract )._admins( msg.sender )   ){		}
		else {			require( auction_info._expiry <= block.timestamp , "ERR() auction not closeable yet" );
		}
		require( auction_info._status > 0 , "ERR() invalid auction id" ) ; // sale not valid
		Bid_info memory bid_info		= _batch_hashid_bidinfo [ _batch_hashid ] ;
		require (bid_info._bidcount > 0 , "ERR() no bid found");
		uint256 bidamount = bid_info._amount ;
		require (bidamount >= auction_info._offerprice , "ERR() price not met" ); // sanity check
		address paymenttoken = auction_info._paymenttoken ;
		require( address(this).balance >= bidamount , "ERR() contract balance not enough" );
		if( paymenttoken == address(0) ){
			/**** admin */
			uint256 admin_fee_rate = IAdmin_nft(_admin_contract)._action_str_fees("CLOSE_AUCTION") ;
			if(admin_fee_rate == 0 ){ admin_fee_rate = ADMIN_FEE_RATE_DEF ;} 
			else {}
			uint256 remaining_amount = bidamount ;
			uint256 admin_fee_amount = bidamount * admin_fee_rate / 10000 ;
			address vault_contract = IAdmin_nft(_admin_contract)._vault();
			if( vault_contract == address(0) ){revert("ERR() vault address invalid"); }
			payable( vault_contract ).call {value : admin_fee_amount } (""); 
/**			emit DepositToVault (
				address(this)
				, admin_fee_amount
				, SEND_TYPES.ADMIN_FEE_AUCTION_ENGLISH
				, vault_contract
			);*/
			remaining_amount -= admin_fee_amount ;
			/***** referer */
			uint referer_feerate = auction_info._referer_feerate ;
			if(referer_feerate>0){
				address referer = bid_info._referer ;
				if(referer == address(0)){}
				else {
					uint pay_referer_when =  IAdmin_nft(_admin_contract)._PAY_REFERER_IMMEDIATE_OR_PERIODIC () ;
					uint256 referer_fee_amount = bidamount * referer_feerate / 10000 ;
					if( pay_referer_when == uint256(PAY_REFERER_IMMEDIATE_OR_PERIODIC.IMMEDIATE)  ){
						payable( referer ).call{value : referer_fee_amount } ("");
					} else if ( pay_referer_when ==uint256(PAY_REFERER_IMMEDIATE_OR_PERIODIC.PERIODIC)  ) {	
                        IPayroll_fees( _payroll ).increment_balance ( referer , 1 , referer_fee_amount , uint256 ( Fee_taker_role.REFERER) ) ;  // function increment_balance (address _address , int256 _addend , uint _taker_role ) external  ;
						vault_contract.call {value : referer_fee_amount } ("") ;	
/**						emit DepositToVault(
							address(this)
							, referer_fee_amount
							, SEND_TYPES.REFERER_FEE_DEPOSIT
							, vault_contract
						);
					}*/
					remaining_amount -= referer_fee_amount ;
				    }
                }
			} else {}
			/****** royalty */
			if( auction_info._target_item_ids.length > 1 ){ // need policy on
			} else {
				uint256 tokenid = auction_info._target_item_ids [ 0 ] ;
				uint author_royalty_rate = IERC1155 ( auction_info._target_contract )._author_royalty ( tokenid ) ;
				if ( author_royalty_rate > 0 ) {
					address author = IERC1155 ( auction_info._target_contract )._author (tokenid) ; // order_sell.asset_contract_offer
					if (author == address(0)){ }
					else {
						uint256 author_royalty_amount = bidamount * author_royalty_rate / 10000 ;
						uint pay_author_when = IAdmin_nft( _admin_contract)._PAY_AUTHOR_IMMEDIATE_OR_PERIODIC() ;
						if ( pay_author_when ==uint256(PAY_AUTHOR_IMMEDIATE_OR_PERIODIC.IMMEDIATE ) ){
							payable( author ).call { value : author_royalty_amount } ("") ;
						}
						else if (pay_author_when ==uint256(PAY_AUTHOR_IMMEDIATE_OR_PERIODIC.PERIODIC ) )
						{	IPayroll_fees( _payroll ).increment_balance ( author , 1 , author_royalty_amount ,uint256(Fee_taker_role.AUTHOR ) ) ;
							vault_contract.call { value : author_royalty_amount } (""); 
/**							emit DepositToVault (
								address(this)
								, author_royalty_amount
								, SEND_TYPES.AUTHOR_ROYALTY_DEPOSIT
								, vault_contract
							) ;*/
						}
						remaining_amount -= author_royalty_amount ;
					}
				}
				else {}
			}
			// remaining of sales proceeds
			payable( auction_info._holder ).call{value: remaining_amount } ("") ;
		}
		else {}
		IERC1155 ( auction_info._target_contract ).safeBatchTransferFrom ( address(this)
			, bid_info._bidder
			, auction_info._target_item_ids
			, auction_info._amounts
			, "" // _calldata
		) ; //     function safeBatchTransferFrom( address from, address to,			uint256[] memory ids, 			uint256[] memory amounts, bytes memory data    ) public virtual override {			
		reinit_auction_data ( _batch_hashid ) ;
	} // to be called by admin only?
	function can_manage_sale ( address _address 
		, Auction_info_batch memory auction_info 
    ) public returns ( bool ) {
		address holder = auction_info._holder ;
		if (    msg.sender == auction_info._opener  // || msg.sender == IProxyRegistry( _user_proxy_registry).proxies ( holder )
			){return true ;} // , "ERR() not privileged"
		else {return false ;}
	}
	function revise_auction_terms ( bytes32 _batch_hashid , Auction_info_batch memory auction_info_update ) 
		public 		
	{
		Bid_info memory bid_info = _batch_hashid_bidinfo [ _batch_hashid ] ;
		if ( bid_info._active ){ // if a bid exists , revert | return false
			revert( "ERR() a bid already placed"); //			return false ;			
		}
		require ( auction_info_update._expiry > block.timestamp , "ERR() invalid expiry arg" );
		Auction_info_batch storage auction_info = _batch_hashid_auction_info [ _batch_hashid ] ;
		if(can_manage_sale ( msg.sender , auction_info )){}
		else {revert("ERR() not privileged");}
		address holder = auction_info._holder ;
		require (  msg.sender == auction_info._opener // || msg.sender == IProxyRegistry( _user_proxy_registry).proxies( holder )
		 , "ERR() not privileged" );

		auction_info._expiry = auction_info_update._expiry ;
		auction_info._offerprice = auction_info_update._offerprice ;
		auction_info._referer_feerate = auction_info_update._referer_feerate ;
	}
	function cancel_auction ( bytes32 _batch_hashid ) public returns (bool) {
//		if ( _batch_hashid_auction_info){}
		if ( _is_batch_hashid_onauction[ _batch_hashid ] ){}
		else {	revert("ERR() auction hash value not found"); 		}
		Auction_info_batch  memory auction_info = _batch_hashid_auction_info [ _batch_hashid ] ;
		if(can_manage_sale ( msg.sender , auction_info )){} 
		require ( auction_info._status > 0 , "ERR() invalid auction") ;
		address holder = auction_info._holder ;
		if ( msg.sender == holder // || msg.sender == IProxyRegistry(_user_proxy_registry ).proxies( holder) 
		) {} 
		else {revert("ERR() not privileged");}
		Bid_info memory bid_info = _batch_hashid_bidinfo [ _batch_hashid ] ;
		if ( bid_info._active ){	revert("ERR() a bid already placed") ;					} 
		else {}		
		reinit_auction_data ( _batch_hashid );
		return true;
	}
	function only_owner_or_admin (address _address ) internal returns ( bool ) {
		if ( _address == _owner || IAdmin_nft( _admin_contract )._admins( _address ) ){return true ; }
		else {return false; } 
	}
	function set_user_proxy_registry( address _address ) public {
		require(only_owner_or_admin(msg.sender) , "ERR() , not privileged" ) ; // require( msg.sender == _owner || IAdmin_nft( _admin_contract )._admins[msg.sender] , "ERR() , not privileged") ;
		_user_proxy_registry = _address ;
	}
	function set_admin_contract (address _address) public {
		require(only_owner_or_admin(msg.sender) , "ERR() , not privileged" ) ; // require(msg.sender == _owner || IAdmin_nft( _admin_contract )._admins[msg.sender] , "ERR() , not privileged"  );
		_admin_contract = _address ;
	}
	function set_erc1155_repo_contract (address _address) public { 
		require(only_owner_or_admin(msg.sender) , "ERR() , not privileged" ) ; // require(msg.sender == _owner || IAdmin_nft( _admin_contract )._admins[msg.sender] , "ERR() , not privileged"  );
		_erc1155_contract = _address ;	
	}
	function set_payroll (address _address ) public {
		require(only_owner_or_admin(msg.sender) , "ERR() , not privileged" ) ; 
		_payroll = _address ;
	}
    	function withdraw_fund (uint256 _amount , address _paymeans, address _to ) public {
		require (msg.sender == _owner , "ERR() only owner" );
		if(_paymeans == address(0)){
			(payable (_to)).send ( _amount);
		}
		else { } // IERC20(_paymeans).transfer ( _to , _amount) ; }
	}

}
