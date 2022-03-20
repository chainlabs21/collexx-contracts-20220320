
pragma solidity ^0.8.0;
contract Admin_nft {
	// minting policy
	address public _owner ;
	mapping (address => bool ) public _admins ;
	uint public ADMIN_FEE_INBP_DEF = 250 ; //  opensea's
	uint256 public REFERER_FEE_DEF = 100 ;
	mapping (string => uint ) public _action_str_fees; // all fee units are in basis points
	mapping (uint => uint ) public _action_uint_fees ; //

	address public _vault ;
	uint256 public _author_royalty_max = 1000 ; // 10%
	uint256 public _referer_fee_max = 500 ; // 5%
	uint256 public _min_balance_required_author_royalty = 0 ;
	uint256 public _min_balance_required_referer_fee = 0;

	uint256 public _last_minute_call_timewindow = 10 * 60 ; // 10 min * 60 sec
	uint256 public _timelength_to_extend_last_minute_call_by =  10 * 60 ; // 10 min * 60 sec

	address public _user_black_white_list_registry ; 
	bool public _allow_duplicate_datahash = false ; // need to decide on default value	
	uint256 public ADMIN_FEE_RATE_DEF = 250 ;
	address public _user_proxy_registry ;
  uint256 public _use_user_black_whitelist_or_none ;

	address public _payroll_fees_contract ;
	enum USER_ACCESS_REFERENCES_BLACK_WHITELIST_NONE {
		__SKIPPER__ // measure against default 0 return 		, 
		,	NONE
		, BLACKLIST
		, WHITELIST
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
	uint public _PAY_REFERER_IMMEDIATE_OR_PERIODIC = uint256(PAY_REFERER_IMMEDIATE_OR_PERIODIC.PERIODIC)  ; // default
	uint public  _PAY_AUTHOR_IMMEDIATE_OR_PERIODIC = uint256 (PAY_AUTHOR_IMMEDIATE_OR_PERIODIC.PERIODIC)  ;
	function set_PAY_REFERER_IMMEDIATE_OR_PERIODIC ( uint _choice ) public onlyadmin( msg.sender ){ 
		if( _PAY_REFERER_IMMEDIATE_OR_PERIODIC == _choice ) {revert("ERR() redundant call");}
		_PAY_REFERER_IMMEDIATE_OR_PERIODIC = _choice ;
	}
	function set_PAY_AUTHOR_IMMEDIATE_OR_PERIODIC ( uint _choice ) public onlyadmin ( msg.sender) {
		if( _PAY_AUTHOR_IMMEDIATE_OR_PERIODIC == _choice)	{	revert("ERR() redundant call"); }
		_PAY_AUTHOR_IMMEDIATE_OR_PERIODIC = _choice ;
	}
	function set_timelength_to_extend_last_minute_call_by ( uint256 __timelength_to_extend ) public onlyadmin( msg.sender ) {
		if( _timelength_to_extend_last_minute_call_by == __timelength_to_extend ){revert("ERR() duplicate call"); }
		_timelength_to_extend_last_minute_call_by = __timelength_to_extend ;	
	}
	function set_last_minute_call_timewindow ( uint256 __timewindow_length ) public onlyadmin ( msg.sender )
	{	if( _last_minute_call_timewindow == __timewindow_length ){revert("ERR() duplicate call"); }
		_last_minute_call_timewindow = __timewindow_length ;
	}
	function set_allow_duplicate_datahash ( bool _allow ) public onlyadmin ( msg.sender ) {
		if ( _allow_duplicate_datahash == _allow ) {	revert("ERR() duplicate call"); }
		_allow_duplicate_datahash = _allow ;
	}
	modifier onlyadmin (address _address) {require( _admins[_address] ) ; _; }
	function set_admin ( address _address , bool _status ) public {
		require( msg.sender == _owner, "ERR(36974) @admin , not privileged");
		if ( _admins [_address] == _status ){revert("ERR() redundant call") ; }
		_admins [_address] = _status ;
	}
	function set_author_royalty_max (uint _maxvalue ) public onlyadmin(msg.sender ) {
		if( _author_royalty_max == _maxvalue ){revert("ERR() redundant call") ; }
        require( _maxvalue < 5000 , "ERR() max exceeded");
		_author_royalty_max = _maxvalue ;
	}
	function set_referer_fee_max ( uint _maxvalue ) public onlyadmin(msg.sender) {
		if( _referer_fee_max == _maxvalue ){revert("ERR() redundant call") ; }
		_referer_fee_max = _maxvalue ;
	}
	function set_min_balance_required_author_royalty (uint _min_required ) public onlyadmin(msg.sender) {
		if( _min_balance_required_author_royalty == _min_required ){revert("ERR() redundant call") ; }
		_min_balance_required_author_royalty = _min_required ;
	}
	function set_min_balance_required_referer_fee (uint _min_required ) public onlyadmin(msg.sender) {
		if(_min_balance_required_referer_fee == _min_required ){revert("ERR() redundant call") ; }
		_min_balance_required_referer_fee = _min_required ;
	}
	function set_vault ( address _address ) public onlyadmin ( msg.sender ) {
		if( _vault == _address ){revert("ERR() redundant call"); }
		_vault = _address ;
	}
	function set_use_user_black_whitelist_or_none ( uint256 _use_list ) public onlyadmin ( msg.sender ) {
		if( _use_user_black_whitelist_or_none == _use_list){revert("ERR() redundant call"); }
		_use_user_black_whitelist_or_none = _use_list ;
	}
	function set_action_str_fee (string memory _action_str , uint _fee_bp ) public onlyadmin(msg.sender) {		
		_action_str_fees[ _action_str ] = _fee_bp ;
	}
	function set_user_proxy_registry ( address _address ) public onlyadmin (msg.sender ){
		if( _user_proxy_registry == _address){revert("ERR() redundant call"); }
		_user_proxy_registry = _address ;
	}
	function set_payroll_fees_contract ( address _address) public onlyadmin ( msg.sender ) {
		if ( _address == _payroll_fees_contract ){revert ( "ERR() redundant call");}
		_payroll_fees_contract = _address ;
	}
	constructor (){
		_owner = msg.sender ;
		_admins [ _owner] = true ;
		_use_user_black_whitelist_or_none = uint256(USER_ACCESS_REFERENCES_BLACK_WHITELIST_NONE.NONE) ;

		_action_str_fees["CLOSE_AUCTION"] = ADMIN_FEE_INBP_DEF ;
		_action_str_fees["MINT"]=0; // ADMIN_FEE_INBP_DEF ;
		_action_str_fees["MINT_SINGLE"]=0; // ADMIN_FEE_INBP_DEF ; 

		_action_str_fees["PUT_ONSALE"]=ADMIN_FEE_INBP_DEF ;
		_action_str_fees["MINT_AND_SELL"]=ADMIN_FEE_INBP_DEF ;
		_action_str_fees["EDIT_SALE_TERMS"]=ADMIN_FEE_INBP_DEF ;  
		_action_str_fees["SET_SALE_TERMS"]=ADMIN_FEE_INBP_DEF ;

		_action_str_fees["SET_SALE_EXPIRY"]=ADMIN_FEE_INBP_DEF ;
		_action_str_fees["CHANGE_PRICE"]=ADMIN_FEE_INBP_DEF ;
		_action_str_fees["SET_PAYMEANS"]=ADMIN_FEE_INBP_DEF ;
		_action_str_fees["APPROVE_BID"]=ADMIN_FEE_INBP_DEF ; // BUY_REQUEST
		_action_str_fees["DENY_BID"]=ADMIN_FEE_INBP_DEF ; // BUY_REQUEST
		_action_str_fees["CANCEL_SALE"]=ADMIN_FEE_INBP_DEF ;
		_action_str_fees["PUT_BID"]=ADMIN_FEE_INBP_DEF ;
		_action_str_fees["CANCEL_BID"]=ADMIN_FEE_INBP_DEF ;

		_action_str_fees["BID_DUTCH_BULK"] = ADMIN_FEE_INBP_DEF ;
		_action_str_fees["MATCH"] = ADMIN_FEE_INBP_DEF ;
		_action_str_fees["MINT_AND_MATCH_SINGLE"] = ADMIN_FEE_INBP_DEF ;		
	}
}
