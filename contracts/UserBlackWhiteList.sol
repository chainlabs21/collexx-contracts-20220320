pragma solidity ^0.8.0;
// import "./OwnableDelegateProxy.sol";
// import "./Interfaces/IERC1155.sol" ;
// import "./openzeppelin/access/Ownable.sol" ; 
import "./Interfaces/IAdmin_nft.sol" ;
// import "./Interfaces/IPayroll_fees.sol" ;
// import "./Utils.sol" ;

contract UserBlackWhiteList {
	address public _owner ;
	mapping ( address => bool ) _blacklist ;
	mapping ( address => bool ) _whitelist ;
	address public _admin_contract ;

	function only_owner_or_admin (address _address ) internal returns ( bool ) {
		if ( _address == _owner || IAdmin_nft( _admin_contract )._admins( _address ) ) {return true ; }
		else {return false; } 
	}
	constructor (
		address __admin_contract
	) {
		_admin_contract = __admin_contract;
		_owner = msg.sender ;
	}
	function set_blacklist (
		address _address
		, bool _status
	) public {
		require ( only_owner_or_admin ( msg.sender ) , "ERR() not privileged" ) ;
		require ( _blacklist [ _address ] != _status , "ERR() redundant call");
		_blacklist [ _address ] = _status ;
	}
	function set_whitelist (
		address _address
		, bool _status
	) public {
		require ( only_owner_or_admin ( msg.sender ) , "ERR() not privileged" ) ;
		require ( _whitelist [ _address ] != _status , "ERR() redundant call");
		_whitelist [ _address ] = _status ;
	}
	function set_admin_contract (address _address) public {
		require(msg.sender == _owner || IAdmin_nft( _admin_contract )._admins ( msg.sender ) , "ERR() , not privileged"  );
		require ( _admin_contract != _address , "ERR() redundant call");
		_admin_contract = _address ;
	}
}
