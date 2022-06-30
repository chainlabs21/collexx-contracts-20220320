pragma solidity ^0.8.0;
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