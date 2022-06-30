pragma solidity ^0.8.0;
import "./Interfaces/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/IVerify-signature.sol" ;
import "./Interfaces/IERC1155.sol";
import "./Interfaces/ISaleInfo.sol";
import "./utils/Signing_admins.sol";
import "./Interfaces/IAdmin_nft.sol";
//import "hardhat/console.sol";

interface IRaffle_info {
	struct Raffle_info {
		address _target_erc1155_contract ;
		string[] _itemids ;
        string[] _revealedids;
		address[] _sellers ;
        uint256[] _royalties;
		address _paymeansaddress ;
		uint256 _offerprice ;
		uint256 _royalty;
		uint256 _expiry ;
		bool _status ;
	}

	struct Raffle_Mint {
		string itemid;
		address author;
		uint256 royalty;
		uint256 decimals;
	}
}
contract Raffle is SaleInfo , IRaffle_info , Ownable {
	mapping ( string => Raffle_info ) public _map_raffle_info ;
	mapping ( address => mapping ( string => bool )) public _map_user_raffle_status ;
	mapping ( string => address [] ) public  _map_uuid_players ;
	mapping ( string => uint256 ) public  _map_uuid_salesamount ;
	mapping ( string => uint256 ) public  _map_uuid_countplayers ;
	mapping ( string => address[] ) public _map_uuid_winners;
	mapping ( string => mapping(address => uint256 )) public _map_uuid_winnings;
	mapping ( string => mapping(address=>string[]) ) public _map_uuid_winners_itemids; 
	mapping ( string => uint256) public _raffle_open_count;
	mapping (string => mapping(address=> string[])) public _map_uuid_winning_items;
    mapping (string => uint256) public _itemid_royalty;
    mapping (string => string) public _itemid_revealedid;
    mapping (string => address) public _itemid_author;
	address public _feecollector ;
    address public _admincontract;

    constructor( address __admincontract){
        _admincontract = __admincontract;
    }

	function set_feecollector ( address _address ) public onlyOwner {
		require ( _address != _feecollector , "ERR() redundant call");
		_feecollector = _address ;
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
	function bid ( string memory _uuid, address _paymentaddress, uint256 _price) public payable{ //UNLIMITED JOIN
		// if ( _map_user_raffle_status[ msg.sender ] [_uuid ] ){revert("ERR() you're already in the raffle");}
		// else {}
		//Raffle_info memory raffleinfo = _map_raffle_info [ _uuid ] ;
		uint256 receivedamount = receivepayment ( _paymentaddress 
			, _price
			, msg.value
			, msg.sender
		) ;
		_map_user_raffle_status[ msg.sender ] [ _uuid ] = true ;
			_map_uuid_players [ _uuid ].push (msg.sender);
		
		_map_uuid_salesamount [ _uuid ] += receivedamount ;
		++ _map_uuid_countplayers [ _uuid ];
	}

	function one_time_bid ( string memory _uuid, address _paymentaddress, uint256 _price) public payable{ //UNLIMITED JOIN
		 if ( _map_user_raffle_status[ msg.sender ] [_uuid ] ){revert("ERR() you're already in the raffle");}
		 else {}
		//Raffle_info memory raffleinfo = _map_raffle_info [ _uuid ] ;
		uint256 receivedamount = receivepayment ( _paymentaddress 
			, _price
			, msg.value
			, msg.sender
		) ;
		_map_user_raffle_status[ msg.sender ] [ _uuid ] = true ;
			_map_uuid_players [ _uuid ].push (msg.sender);
		
		_map_uuid_salesamount [ _uuid ] += receivedamount ;
		++ _map_uuid_countplayers [ _uuid ];
	}

	function bid_multiplier ( string memory _uuid, address _paymentaddress, uint256 _price, uint256 _multiplier ) public payable{ //UNLIMITED JOIN
		uint256 receivedamount = receivepayment ( _paymentaddress 
			, _price
			, msg.value
			, msg.sender
		) ;
		_map_user_raffle_status[ msg.sender ] [ _uuid ] = true ;
		for (uint256 idx=0; idx<_multiplier; idx++){
			_map_uuid_players [ _uuid ].push (msg.sender);
		}
		_map_uuid_salesamount [ _uuid ] += receivedamount ;
		++ _map_uuid_countplayers [ _uuid ];
	}

	function bid_multiplier_once ( string memory _uuid, address _paymentaddress, uint256 _price, uint256 _multiplier ) public payable{ //UNLIMITED JOIN
	if ( _map_user_raffle_status[ msg.sender ] [_uuid ] ){revert("ERR() you're already in the raffle");}
		 else {}
		uint256 receivedamount = receivepayment ( _paymentaddress 
			, _price
			, msg.value
			, msg.sender
		) ;
		_map_user_raffle_status[ msg.sender ] [ _uuid ] = true ;
		for (uint256 idx=0; idx<_multiplier; idx++){
			_map_uuid_players [ _uuid ].push (msg.sender);
		}
		_map_uuid_salesamount [ _uuid ] += receivedamount ;
		++ _map_uuid_countplayers [ _uuid ];
	}

	function all_in_one_bid ( string memory _uuid, address _paymentaddress, uint256 _price, uint256 _multiplier ) public payable{ //UNLIMITED JOIN
		uint256 receivedamount = receivepayment ( _paymentaddress 
			, _price
			, msg.value
			, msg.sender
		) ;
		_map_user_raffle_status[ msg.sender ] [ _uuid ] = true ;
		for (uint256 idx=0; idx<_multiplier; idx++){
			_map_uuid_players [ _uuid ].push (msg.sender);
		}
		_map_uuid_salesamount [ _uuid ] += receivedamount ;
		++ _map_uuid_countplayers [ _uuid ];
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
	function settle ( string memory _uuid, Raffle_info memory raffleinfo, uint256[] memory _winners ) public {
		if ( _map_uuid_countplayers [ _uuid] == 0 ) {} // none participated
		else {}
		
		if (_map_raffle_info[_uuid]._status ){revert("ERR() raffle already closed"); }
		_map_raffle_info[ _uuid] = raffleinfo;
		for (uint256 widx=0; widx < _winners.length; widx++){
			if(_map_uuid_winnings[_uuid][_map_uuid_players [ _uuid ][_winners[widx]]]<1){
				_map_uuid_winnings[_uuid][_map_uuid_players [ _uuid ][_winners[widx]]] = 1;
			}else{
				_map_uuid_winnings[_uuid][_map_uuid_players [ _uuid ][_winners[widx]]]++;
			}
			_map_uuid_winners_itemids[_uuid][_map_uuid_players [ _uuid ][_winners[widx]]].push(raffleinfo._itemids[widx]);
            _itemid_royalty[raffleinfo._itemids[widx]] = raffleinfo._royalties[widx];
            _itemid_author[raffleinfo._itemids[widx]] = raffleinfo._sellers[widx];
            _itemid_revealedid[raffleinfo._itemids[widx]]=raffleinfo._revealedids[widx];
			_map_uuid_winners[_uuid].push(_map_uuid_players [ _uuid ][_winners[widx]]);
		}
		//_map_raffle_info [_uuid]._status = false;
		_raffle_open_count[_uuid] = 0;
	}

	function draw(string memory _uuid) public {
		if(_map_uuid_winnings[_uuid][msg.sender]<1){
			revert("NO MORE ITEMS TO DRAW");
		}
		Raffle_info memory raffleinfo = _map_raffle_info[ _uuid];
		for (uint256 i = 0; i<_map_uuid_winners_itemids[_uuid][msg.sender].length; i++){
			uint256 tokenid = IERC1155 ( raffleinfo._target_erc1155_contract)._itemhash_tokenid ( _map_uuid_winners_itemids[_uuid][msg.sender][i] ) ;
				if ( tokenid == 0 ) {
				tokenid = IERC1155 ( raffleinfo._target_erc1155_contract ).mint (
					_itemid_author[_map_uuid_winners_itemids[_uuid][msg.sender][i]]
					, _map_uuid_winners_itemids[_uuid][msg.sender][i]
                    , _itemid_revealedid[_map_uuid_winners_itemids[_uuid][msg.sender][i]]
					, 1
					, _itemid_royalty[_map_uuid_winners_itemids[_uuid][msg.sender][i]]
					, 0
					, "0x00"
				) ;
				
				}
				IERC1155 ( raffleinfo._target_erc1155_contract ).safeTransferFrom (
					_itemid_author[_map_uuid_winners_itemids[_uuid][msg.sender][i]]
					, msg.sender
					, tokenid
					, 1
					, "0x00"
				) ;	
		}
		_map_uuid_winnings[_uuid][msg.sender]=0;
	}

	function get_winners(string memory _uuid) public view returns(address[] memory){
		return _map_uuid_winners[_uuid];
	}
	function get_winner_items(string memory _uuid, address _username) public view returns(string[] memory){
		return _map_uuid_winners_itemids[_uuid][_username];
	}

	modifier onlyowner ( address _address ) {
        require( _address == _owner , "ERR() not privileged");
    _;
    }
	function withdraw_fund ( address _paymeansaddress 
		, uint256 _amount 
		, address _to
	) public {
        require ( msg.sender == _owner || IAdmin_nft( _admincontract)._admins (msg.sender ) , "ERR() not privileged" ) ;
		makepayment ( _paymeansaddress , _amount , _to ) ;
	}

}