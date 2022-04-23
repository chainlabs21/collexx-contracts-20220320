
pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}
interface IERC1155Receiver is IERC165 {
	function onERC1155Received(
			address operator,
			address from,
			uint256 id,
			uint256 value,
			bytes calldata data
	)
		external
		returns(bytes4);
	function onERC1155BatchReceived(
			address operator,
			address from,
			uint256[] calldata ids,
			uint256[] calldata values,
			bytes calldata data
	)
		external
		returns(bytes4);
}
interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC1155 is IERC165 {
	event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
	event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
	event ApprovalForAll(address indexed account, address indexed operator, bool approved);
	event URI(string value, uint256 indexed id);
	function balanceOf(address account, uint256 id) external view returns (uint256);
	function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
	function setApprovalForAll(address operator, bool approved) external;
	function isApprovedForAll(address account, address operator) external view returns (bool);
	function safeTransferFrom(address from
		, address to
		, uint256 id
		, uint256 amount
		, bytes calldata data) external;
	function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
	function _itemhash ( string memory _itemid ) external view returns ( uint256 ) ;
	function mint (
				uint256
			, string memory
			,	uint256
			, uint256
			, uint256
			, bytes memory
	) external returns ( uint256 );
}
contract Auction {
	mapping ( address => uint256 ) public _balances ;
//	mapping ( bytes => Auction_info ) public _map_offerid_offerinfo ;
	mapping ( string => Auction_info ) public _map_uuid_auctioninfo ;
	mapping ( string => Bid_info ) public _map_uuid_bidinfo ;
	mapping ( bytes => string ) public _map_auction_instance_hash_uuid ;
	mapping ( string => bytes ) public _map_uuid_auction_instance_hash ;
	address public _owner ;
	constructor () {
		_owner = msg.sender ;
	}
	struct Auction_info { //		address _opener ; // 0 // the one who opened this auction on behalf of _seller
		address _seller ; // 0 // assets owner/holder
		address _target_erc1155_contract ; // 1
		uint256 _target_token_id ; // 2
		uint256 _amount ; // 3
		address _paymeansaddress ; // 4
		uint256 _offerprice ;	 // 5
		uint _starting_time ;  // 6
		uint _expiry ; // 7 //		uint _referer_feerate ; // 10
		bool _status ; // 8 
	}
	struct Bid_info {
		address _bidder ; // 0
		uint256 _amount ; // 1
		uint _bidtime ; // 2
		uint _bidcount ; // 3
		address _referer ; // 4
		bool _status ; // 5
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
	function mint_start_auction_and_bid (	
	) public {}
	struct Mint_info {
		address _target_erc1155_contract ;// 0
 		 string _itemid ;// 1
		 uint256 _amounttomint; // 2
		 uint256 _author_royalty ;// 3
		 address _author ; // 4
	}
	function mint_start_auction_and_bid_scalars (
/** 			address _target_erc1155_contract // 0
 		, string memory _itemid // 1
		, uint256 _amounttomint // 2
		, uint256 _author_royalty // 3
		, address _author  // 4*/
		Mint_info memory mintinfo
/******* */
		, address _seller // 5
		, uint256 _amounttobuy // 6
		, uint256 _starting_price // 7
		, address _paymeansaddress // 8
		, uint256 _starting_time // 9
		, uint256 _expiry // 10
		, string memory _uuid // 11 //		, address _buyer // 6
/******* */		
		, uint256 _bidamount //  12
//		, string memory _uuid
	) public payable {
		uint256 tokenid ; // 9
		require ( mintinfo. _amounttomint >= _amounttobuy , "ERR() amount invalid") ;
		if ( (tokenid = IERC1155( mintinfo._target_erc1155_contract )._itemhash ( mintinfo._itemid) )== 0 ){
			tokenid = IERC1155 ( mintinfo. _target_erc1155_contract ).mint (
					mintinfo._author_royalty
				, mintinfo._itemid
				,	mintinfo._amounttomint
				, mintinfo._author_royalty
				, 0
				, "0x00"
			);
		} else {
		}
/** 		if ( (tokenid = IERC1155( _target_erc1155_contract )._itemhash (_itemid) )== 0 ){
			tokenid = IERC1155 ( _target_erc1155_contract ).mint (
					_author_royalty
				, _itemid
				,	_amounttomint
				, _author_royalty
				, 0
				, "0x00"
			);
		} else {
		} */
		if ( _paymeansaddress==address( 0 ) ){
			require( msg.value >= _bidamount , "ERR() amount not met");
		} else {
			if ( IERC20( _paymeansaddress ).transferFrom( msg.sender, address(this) , _bidamount )  ){}
      else {revert( "ERR() amount not met") ; }
		} // _balances [ msg.sender ] += _bidamount ;
//		string memory auctionid = _uuid ;
		Bid_info memory previousbid ;
		if ( _map_uuid_auctioninfo [ _uuid ]._status ){  // already open
			previousbid = _map_uuid_bidinfo [ _uuid ] ;
			if ( previousbid._status ){ // previous bid exists
				require ( _bidamount > previousbid._amount , "ERR() does not outbid" ) ;
			} else {}
		}
		else { // new auction 
			IERC1155 ( mintinfo. _target_erc1155_contract ).safeTransferFrom ( _seller 
				, address (this)
				, tokenid
				, _amounttobuy
				, "0x00"	
			) ;
			_map_uuid_auctioninfo [ _uuid ] = Auction_info (
				_seller
				, mintinfo._target_erc1155_contract
				, tokenid
				, _amounttobuy
				, _paymeansaddress
				, _starting_price
				, _starting_time
				, _expiry
				, true
			) ;
			_map_uuid_bidinfo [_uuid ] = Bid_info (
				msg.sender
				, _bidamount
				, block.timestamp
				, 1 + previousbid._bidcount
				, address(0)
				, true
			) ;
//			_map_uuid_auction_instance_hash [] = 			 abi.encodePacked (			)  ;
		}
	}
	function initauctionmap ( string memory _uuid ) internal {
		_map_uuid_auctioninfo [ _uuid ] = Auction_info (
				address (0) // 0
			, address (0) // 1
			, 0 // 2 
			, 0 // 3
			, address (0) // 4
			, 0 // 5
			, 0 // 6
			, 0 // 7
			, false // 8
		) ;
	}
	function initbidmap ( string memory _uuid ) internal {
		_map_uuid_bidinfo [ _uuid ] = Bid_info (
				address(0) // 0
			, 0 // 1
			, 0 // 2
			, 0 // 3
			, address(0) // 4
			, false // 5
		);
	}
	function cancel_bid ( string memory _uuid ) public {
		Bid_info memory bidinfo = _map_uuid_bidinfo [ _uuid ] ;
		if ( bidinfo._status ){}
		else {revert("ERR() bid does not exist") ; }
		require ( msg.sender == bidinfo._bidder , "ERR() not privileged");
		if ( bidinfo._bidcount >1){revert("ERR() subsequent bids cannot be canceled");}
		else {}
		Auction_info memory auctioninfo = _map_uuid_auctioninfo [ _uuid ] ;
		if ( auctioninfo._status ){ // this should hold			
		} else { revert("ERR() auction info not found"); }
		makepayment ( auctioninfo._paymeansaddress
			, bidinfo._amount
			, bidinfo._bidder
		);
		initbidmap ( _uuid );
	}
	function settle ( string memory _uuid ) public {
		Auction_info memory auctioninfo = _map_uuid_auctioninfo [ _uuid ] ;
		if ( auctioninfo._status ){}
		else {revert("ERR() invalid offer"); }
		if ( auctioninfo._expiry <= block.timestamp ){ }
		else { revert("ERR() expiry not reached yet");
		}
		Bid_info memory bidinfo = _map_uuid_bidinfo [ _uuid ] ;
		if ( bidinfo._status ){
			makepayment ( auctioninfo._paymeansaddress 
				, bidinfo._amount
				, auctioninfo._seller
			) ;
			IERC1155( auctioninfo._target_erc1155_contract ).safeTransferFrom (
				address( this )
				, bidinfo._bidder
				, auctioninfo._target_token_id
				, auctioninfo._amount
				, "0x00"
			);
		} // 
		else {} // no bid
		initbidmap (_uuid ) ;
		initauctionmap( _uuid ) ;
	}
	modifier onlyowner ( address _address ) {
    require( _address == _owner , "ERR() not privileged");
    _;
  }
	function withdraw_fund ( address _paymeansaddress 
		, uint256 _amount 
		, address _to
	) public onlyowner ( msg.sender ){
		makepayment ( _paymeansaddress , _amount , _to ) ;
	}
}
/**Auction
	Mint_and_start_auction (민팅 후, 옥션 데이터를 등록합니다. 경매 인스턴스 아이디는 uuid로 arguments를 통해 제공합니다.)
	Bid (경매 비딩을 합니다.)
	Cancel_listing (비딩을 철회합니다.)
	Extend_expiry_on_bid (경매 마감시간이 10분 이하로 남았을때 10분 연장을 하게됩니다.)
	Validate_auction_open 경매의 존재 여부를 확인을 합니다.
	Settle_auction (경매 정산을 합니다. 관리자, 판매자, 그리고 마지막 입찰자가 접근 가능합니다.)
	Withdraw (컨트랙트에 보관 중이던 토큰을 관리자 지갑 주소로 인출합니다.)
*/