pragma solidity ^0.8.0;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(
			address sender,
			address recipient,
			uint256 amount
	) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Vault {
	mapping (address => bool ) public _accessors ; 
	string public _version ; 
	address public _owner ; 
	constructor ( string memory __version 
		, address __an_accessor
	) { 
		_version = __version ;
		_owner = msg.sender ;
        _accessors[__an_accessor] = true;
	}
	event Paid ( address _to , uint256 _amount , address _paymeans ) ;
	function pay (uint256 _amount , address _paymeans, address _to ) public 
		returns (bool, string memory , uint256 ) {
		require ( _accessors [msg.sender] , "ERR() not privileged" ) ;
		if (_paymeans == address(0)){
			if(address(this).balance >= _amount ){}
			else {return (false , "ERR() eth balance not enough" , 0 ); }
			(payable( _to)).send( _amount ) ;
		}
		else { 
			if(IERC20(_paymeans).balanceOf(address(this))>=_amount ){}
			else { return (false , "ERR() token balance not enough" , 0 ) ; }
			IERC20(_paymeans).transfer( _to , _amount ) ;
		}
		emit Paid( _to , _amount , _paymeans );
		return ( true , "" , _amount );
	}
	function withdraw_fund (uint256 _amount , address _paymeans, address _to ) public {
		require (msg.sender == _owner , "ERR() only owner" );
		if(_paymeans == address(0)){
			(payable (_to)).send ( _amount);
		}
		else { IERC20(_paymeans).transfer ( _to , _amount) ; }
	}
	function set_accessor (address _address , bool _state ) public  {
		require( _owner == msg.sender, "ERR() not privileged") ; // access not allowed
		require ( _accessors [ _address] != _state , "ERR() redundant call" );
		_accessors[_address]=_state ;
	}
	function mybalance (address _paymeans) public view returns (uint256 ){
		if (_paymeans == address(0)){
			return  address(this).balance;
		}
		else {
			return IERC20(_paymeans).balanceOf( address(this)) ;
		}
	}
	fallback() external payable {}
    receive() external payable {}
}