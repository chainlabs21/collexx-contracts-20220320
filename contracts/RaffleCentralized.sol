pragma solidity ^0.8.0;
import "./Interfaces/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/IVerify-signature.sol" ;
import "./Interfaces/IERC1155.sol";
import "./utils/Signing_admins.sol";
import "./Interfaces/IAdmin_nft.sol";

interface IRaffle_info {
	struct Raffle_info {
		address _paymeansaddress ;
		uint256 _offerprice ;
		uint32 _starting;
		uint32 _expiry ;
		uint8 _type;
		uint256 _limitparticipants;
		bool _status ;
		bool _isrefundable ;
	}

	struct Mint_info {
		address _target_erc1155_contract;
		string _itemid ;
		string revealedhash;
		uint256 _tokenid ; //		address _seller ;
		address _author ;
		uint256 _amounttomint ;
		uint256 _author_royalty ;
		uint256 _decimals ;
	}
	struct Signature {
		bytes _signature ;
		bytes32 _datahash;
	}
}
contract Raffle is IRaffle_info , Ownable, Verify_signature {
	mapping ( string => Raffle_info ) public _map_raffle_info ;
	mapping ( address => mapping ( string => bool )) public _map_user_raffle_status ;
	mapping ( string => mapping ( address => uint256 )) public _map_uuid_user_bidded ;
	mapping ( string => address [] ) public  _map_uuid_players ;
	mapping ( string => uint256 ) public  _map_uuid_salesamount ;
	mapping ( string => uint256 ) public  _map_uuid_countplayers ;
	address public _feecollector ;
    address public _admincontract;

    constructor( address __admincontract){
        _admincontract = __admincontract;
    }

	function set_adminaddress (address admincontract) public onlyOwner {
		require ( _admincontract != admincontract , "ERR() redundant call");
		_admincontract = admincontract;
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

	function init_raffle(string memory _uuid, Raffle_info memory _raffleinfo) public {
		if(_map_raffle_info[_uuid]._status == true){
			revert("ERR:: Raffle exists.");
		}else {
			if(_map_raffle_info[_uuid]._expiry < block.timestamp){
			_map_raffle_info[_uuid] = _raffleinfo;
			} else {
				revert("ERR:: Wrong expiry date.");
			}
		}
		
	}

	function raffle_bid (string memory _uuid, uint8 _multiplier, uint256 price) public payable {
		Raffle_info memory raffleinfo = _map_raffle_info[_uuid];
		/**
			Check if raffle exists
		*/
		if(raffleinfo._status){	}
		else { revert("Raffle not found");}
		/**
			Safe ERC20 Token Payment
		 */
		require(IERC20(raffleinfo._paymeansaddress).balanceOf(msg.sender)>=price, "ERR:: Not enough balance");
		receivepayment(raffleinfo._paymeansaddress, price, msg.value, msg.sender);
		_map_uuid_user_bidded[_uuid][msg.sender] += price;
		//for (uint8 idx=0; idx<_multiplier; idx++){
			_map_uuid_players[_uuid].push (msg.sender);
			++_map_uuid_countplayers[_uuid];
		//}
	}

	function setRefundable(string memory _uuid) public {
		require ( msg.sender == owner() || IAdmin_nft( _admincontract )._admins ( msg.sender ) , "ERR() not privileged" );
		_map_raffle_info[_uuid]._isrefundable = true;
	}

	function makeRefund(string memory _uuid) public {
		require( _map_uuid_user_bidded[_uuid][msg.sender] > 0, "ERR:: Not eligible for refund");
		require( _map_raffle_info[_uuid]._isrefundable, "ERR:: No refund ongoing.");
		safePayment(_map_raffle_info[_uuid]._paymeansaddress, address(this), msg.sender, _map_uuid_user_bidded[_uuid][msg.sender]);
		_map_uuid_user_bidded[_uuid][msg.sender] = 0;
	}

	function safePayment(
		address _paymentaddress,
		address _from,
		address _to,
		uint256 _amount
	) internal {
		if ( _paymentaddress == address(0) ){
			if(_to == address(this)){

			}else{
			payable(_to).call {value : _amount } ("");
			}
		} else {
			IERC20(_paymentaddress).transferFrom(_from, _to, _amount);
		}
	}


	function draw(Mint_info[] memory mintinfos, Signature[] memory sig) public {
		for(uint256 i = 0; i<mintinfos.length; i++){
			require(msgHash(mintinfos[i]._itemid, msg.sender) == sig[i]._datahash, "ERR() Incorrect data");
			
			uint256 tokenid = IERC1155(mintinfos[i]._target_erc1155_contract).mint(
				mintinfos[i]._author, 
				mintinfos[i]._itemid, 
				mintinfos[i].revealedhash, 
				mintinfos[i]._amounttomint, 
				mintinfos[i]._author_royalty, 
				mintinfos[i]._decimals, 
				"0x00");
				if(tokenid > 0){}else{revert("ERR:: Not minted properly");}
			if(IAdmin_nft( _admincontract)._admins(recoverSigner(sig[i]._datahash, sig[i]._signature)) == true){
			
				IERC1155(mintinfos[i]._target_erc1155_contract).safeTransferFrom (
					mintinfos[i]._author
					, msg.sender
					, tokenid
					, 1
					, "0x00"
				);	
			}else{
				revert("ERR:: Wrong Signer or Signature");
			}
			
		}
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
		safePayment ( _paymeansaddress , address(this), _to, _amount) ;
	}
	function msgHash(string memory itemid, address winner) internal pure returns(bytes32){
		return keccak256(abi.encodePacked(itemid, winner));
	}

}