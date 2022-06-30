pragma solidity ^0.8.0;

interface IVault {
//	function getmindeltabid() returns (uint256) ;
//	function getpaymeansstatus (address _paymeans 	)			external view returns (uint);
	// function get_current_tokenid_counter () external view returns (uint) ;
//	function increment_tokenid () external ;
//	mapping (uint256 => bool ) external _maptokenidtoisonsale ;
//	function do_transfer_from (address _spender ,  address _paymeans , uint256 _amount) external;	
	function _accessors (address _address ) external view returns (bool);
	function pay (address _paymeans , uint256 _amount , address _to) external returns (bool, string memory , uint256) ;
	function withdraw_fund (uint256 _amount , address _paymeans, address _to ) external ;
	function set_accessor (address _address , bool _state ) external;
	function mybalance (address _paymeans) external view returns (uint256 );
} 