pragma solidity ^0.8.0;
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

	//function _ADMIN_owner () external view returns ( address ) ;

	function ADMIN_FEE_RATE_DEF () external view returns ( uint256 ) ;
	function _admins (address _address) external view returns (bool) ;
	function set_admin ( address _address , bool _status ) external ;

	function set_action_str_fee ( string memory _action_str ) external ;
	function _action_str_fees ( string memory _action_str ) external view returns ( uint ) ;
	function _action_str_fees_bool (string memory _action_str) external view returns (bool);

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