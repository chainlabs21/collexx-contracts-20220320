
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./IVerify-signature.sol" ;
import "./IERC1155.sol";
import "./interface_sale_info.sol";
import "./Signing_admins.sol";

interface IRaffle_info {
	struct Raffle_info {
		address _target_erc1155_contract ;
		string _itemid ;
		uint256 _tokenid ;
		address _seller ;
		address _paymeansaddress ;
		uint256 _offerprice ;
		uint256 _amounttosell ;
		bool _status ;
		uint256 _expiry ;
	}
}
contract Raffle is Sale_info , IRaffle_info , Ownable {
	mapping ( string => Raffle_info ) public _map_raffle_info ;
	mapping ( address => mapping ( string => bool )) public _map_user_raffle_status ;
	mapping ( string => address [] ) public  _map_uuid_players ;
	mapping ( string => uint256 ) public  _map_uuid_salesamount ;
	mapping ( string => uint256 ) public  _map_uuid_countplayers ;
	address public _feecollector ;
	function set_feecollector ( address _address ) public onlyOwner {
		require ( _address != _feecollector , "ERR() redundant call");
		_feecollector = _address ;
	}
	function init_raffle_sale (
		Mint_info memory mintinfo
		, Raffle_info memory raffleinfo
		, string memory _uuid
	) public {
		uint256 tokenid = IERC1155 ( mintinfo._target_erc1155_contract)._itemhash_tokenid ( mintinfo._itemid ) ;
		if ( tokenid == 0 ) {
			tokenid = IERC1155 ( mintinfo._target_erc1155_contract ).mint (
				mintinfo._author
				, mintinfo._itemid
				, mintinfo._amounttomint
				, mintinfo._author_royalty
				, mintinfo._decimals
				, "0x00"
			) ;
		}		
		if (_map_raffle_info[ _uuid]._status ) {} // has been already registered
		else {}
		raffleinfo._tokenid = tokenid ;
		_map_raffle_info[ _uuid] =raffleinfo ;  // overwrite for ease of dev
	}
	function receivepayment (
			address _paymeansaddress
		, uint256 _amounttopay
		, uint256 _msgvalue
		, address _payer
//		, address _receiver
	) internal returns ( uint256 receivedamount_ ){
		if ( _paymeansaddress == address(0) ){
			if ( _msgvalue >= _amounttopay ){}
			else {revert("ERR() price amount not met"); }
			receivedamount_ = _msgvalue ;
		}
		else {
			IERC20 ( _paymeansaddress ).transferFrom ( _payer , address(this) , _amounttopay ) ;
			receivedamount_ = _amounttopay ;
		}
	}
	function bid ( string memory _uuid ) public {
		if ( _map_user_raffle_status[ msg.sender ] [_uuid ] ){revert("ERR() you're already in the raffle");}
		else {}
		Raffle_info memory raffleinfo = _map_raffle_info [ _uuid ] ;
		uint256 receivedamount = receivepayment ( raffleinfo._paymeansaddress 
			, raffleinfo._amounttopay
			, msg.value
			, msg.sender
		) ;
		_map_user_raffle_status[ msg.sender ] [ _uuid ] = true ;
		_map_uuid_players [ _uuid ].push (msg.sender );
		_map_uuid_salesamount [ _uuid ] += receivedamount ;
		++ _map_uuid_countplayers ;
	}
	function makepayment (
			address _paymeansaddress
		, uint256 _amounttopay
		, address _receiver
	) internal {
		if ( _paymeansaddress == address(0) ){
			payable( _receiver).call {value : _amounttopay } ("");
		}
		else {
			IERC20 ( _paymeansaddress ).transfer ( _receiver , _amounttopay ) ;
		}
	}
	function draw_and_settle ( string memory _uuid ) public {
		if ( _map_uuid_countplayers [ _uuid] == 0 ) {} // none participated
		else {}
		Raffle_info memory raffleinfo = _map_raffle_info [ _uuid ]  ;
		if (raffleinfo._status ){}
		else { revert("ERR() raffle already closed"); }
		uint256 N =_map_uuid_countplayers [ _uuid] ;
		uint256 idxwinner = ( block.timestamp + block.difficulty) % N ;
		address winner = _map_uuid_players [ _uuid] [ idxwinner ];
		IERC1155 ( raffleinfo._target_erc1155_contract ).safeTransferFrom (
			raffleinfo._seller
			, winner //			, address( this )
			, raffleinfo._tokenid
			, raffleinfo._amounttosell
			, "0x00"
		) ;
		address paymeansaddress = raffleinfo._paymeansaddress  ;
		makepayment ( paymeansaddress
			, raffleinfo._offerprice
			, _feecollector
		) ;
		for ( uint256 idx=0; idx<N;idx++){
			address refundreceiver = _map_uuid_players [_uuid] [ idx];
			if ( idx == idxwinner){continue ;}
			makepayment ( paymeansaddress 
				, raffleinfo._offerprice
				, refundreceiver
			);
			_map_user_raffle_status[ refundreceiver ][ _uuid]  = ; // mapping ( address => mapping ( string => bool )) public 
		}
		_map_raffle_info [_uuid]._status = false  ; // mapping ( string => Raffle_info ) public
		_map_uuid_players [ _uuid] = [] ; // mapping ( string => address [] ) public  
	  _map_uuid_salesamount [ _uuid ] = 0 ; // mapping ( string => uint256 ) public
	  _map_uuid_countplayers [ _uuid ] = 0 ;
	}
}
