

pragma solidity ^0.8.0;
import "./Interfaces/IAdmin_nft.sol";
import "./Interfaces/IVault.sol" ; 
contract Payroll_fees {
//	address public _user_proxy_registry ;
	address public _admin_contract ;
	// address public _erc1155_contract ;
	address _owner ;
	address _vault ; 
//	mapping (address =>  int256 ) public _bala nces ;
	mapping (address => mapping(uint => uint256 ) ) public _balances ;
	mapping (address => bool ) public _accessors ;
	mapping (address => mapping(uint => uint256 )) public _last_paid_time ; // ain't that sure its necessity , for bookkeeping sake for time being
	// mapping () // keccak256 sig , yet address correspondence is a little obscure
	event BalanceChanged (address _address , uint256 _amount , uint256 _balance );
	constructor ( // address __user_proxy_registry
//		, 
		address __admin_contract
//		, address __erc1155_contract
	) {
		_owner = msg.sender ;
		_admin_contract = __admin_contract ;
//		_user_proxy_registry = __user_proxy_registry ;
	//	_erc1155_contract = __erc1155_contract;
	}
	enum Fee_taker_role {
		REFERER
		, AUTHOR
	}
	function payout ( address [] memory _addresses , address __vault ) public {
		uint256 min_required_loyalty = IAdmin_nft(_admin_contract)._min_balance_required_author_royalty () ;
		uint256 min_required_referer = IAdmin_nft(_admin_contract)._min_balance_required_referer_fee () ;
		uint256 [2] memory min_required ;
         min_required[0] = min_required_loyalty ;
         min_required[1] = min_required_referer ;
		uint256 count = _addresses.length ;
		uint256 timestamp = block.timestamp ;
		address vault = __vault == address(0)? _vault : __vault ;
		for (uint256 i=0; i<count ; ++i )   { 
            address receiver = _addresses [ i ]  ;
			for (uint fee_taker_role= uint( Fee_taker_role.REFERER ) ; fee_taker_role<=uint(Fee_taker_role. AUTHOR) ; ++fee_taker_role ){
				uint256 balance = (uint256)( _balances[ receiver ][ fee_taker_role] );
				if( balance >=min_required[ fee_taker_role ] ){
					(bool status_ , string memory message_ , uint256 paid_amount_ )= IVault( vault ).pay(address(0) , balance , receiver  ) ; // for the time being , only pay means is eth/klaytn
					if(status_ ){
						_balances[ receiver ][ fee_taker_role ] -= paid_amount_ ;
						_last_paid_time[ receiver ][ fee_taker_role ] = timestamp ; 
					} else {}
				} else {}
			}
		}
	}
// function pay (uint256 _amount , address _paymeans, address _to ) public 		returns (bool, string memory ) {
// unpaid balance gets carried over to next period
enum IncrementDecrement{
	Decrement
	, Increment
}
	function increment_balance ( address _address
		,uint256 incdec
		,  uint256 _addend 
		, uint _taker_role ) 
    public {
		bool canaccess = false;
		if(IAdmin_nft( _admin_contract )._admins( msg.sender)  ){canaccess=true; }
		else {}
		if( _accessors[ msg.sender] ){canaccess = true; }
		else {}
		require( canaccess , "ERR() not privileged" );
		if ( incdec == uint256(IncrementDecrement.Decrement)  ){
			_balances[ _address ][ _taker_role ] -= _addend ;
		}else {
			_balances[ _address ][ _taker_role ] += _addend ;
		}		
		emit BalanceChanged ( _address , _addend , _balances[ _address ][ _taker_role ] ) ;
        //event BalanceChanged (address _address , int256 _amount , int256 _balance );
	}
	modifier only_owner_or_admin ( address _address )  {
		require( _address == _owner || IAdmin_nft( _admin_contract)._admins( _address ) , "ERR() not privileged" );
        _;
	}
	function set_admin_contract (address _address) public {
		require( msg.sender == _owner || IAdmin_nft( _admin_contract )._admins( msg.sender ) , "ERR() , not privileged"  );
		_admin_contract = _address ;
	}
	function set_accessor (address _address , bool _status ) public {
		require(msg.sender == _owner || IAdmin_nft( _admin_contract )._admins(msg.sender) , "ERR() , not privileged"  );
		_accessors[ _address ]  = _status ;
	}
	function set_vault ( address _address ) public {
		require(msg.sender == _owner || IAdmin_nft( _admin_contract )._admins(msg.sender) , "ERR() , not privileged"  );
		_vault = _address ; 
	}
}
/** 	function set_user_proxy_registry( address _address ) {
		require( msg.sender == _owner || IAdmin_nft( _admin_contract )._admins[msg.sender] , "ERR() , not privileged") ;
		_user_proxy_registry = _address ;
	}
	function set_erc1155_contract (address _address) { 
		require(msg.sender == _owner || IAdmi n_nft( _admin_contract )._admins[msg.sender] , "ERR() , not privileged"  );
		_erc1155_contract = _address ;	
	}
*/
