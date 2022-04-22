
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

contract SuggestToSell {
	mapping ( address => uint256 ) public _balances ;
	mapping ( bytes => OfferInfo ) public _map_offerid_offerinfo ;
	mapping ( string => OfferInfo ) public _map_uuid_offerinfo ;
	address public _owner ;
	constructor () {
		_owner = msg.sender ;
	}
	struct OfferInfo {
		address _seller ;
		address _buyer ;
		address _target_erc1155_contract ;
		string _itemid ;
    address _paymeansaddress ;
		uint256 _amounttobuy ;
		uint256 _amounttopay ;
    uint256 _expiry ;
		bool _active ;
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
	function mint_and_offer (
			address _target_erc1155_contract // 0
 		, string memory _itemid // 1
		, uint256 _amounttomint // 2
		, uint256 _author_royalty // 3
		, address _seller // 5
		, address _buyer // 6
		, uint256 _amounttobuy // 7
		, uint256 _amounttopay // 8
		, address _paymeansaddress // 9
		, uint256 _expiry // 10
		, string memory _uuid // 11
//		, string memory _uuid
	) public payable {
		uint256 tokenid ; // 9
		require ( _amounttomint >= _amounttobuy , "ERR() amount invalid") ;
		if ( (tokenid = IERC1155( _target_erc1155_contract )._itemhash (_itemid) )== 0 ){
			tokenid = IERC1155 ( _target_erc1155_contract ).mint (
					_author_royalty
				, _itemid
				,	_amounttomint
				, _author_royalty
				, 0
				, "0x00"
			);
		} else {
		}
		if ( _paymeansaddress==address( 0 ) ){
			require( msg.value >= _amounttopay , "ERR() amount not met");
		} else {
			if ( IERC20( _paymeansaddress ).transferFrom( msg.sender, address(this) , _amounttopay )  ){}
            else {revert( "ERR() amount not met") ; }
		}
		_balances [ msg.sender ] += _amounttopay ;
		bytes memory offerinstanceid = bytes( abi.encodePacked ( 
				_target_erc1155_contract 		
			, _itemid
			, _seller
			, _buyer
			, _amounttobuy
			, _amounttopay
			, _paymeansaddress
			, _expiry
		) ) ;
		_map_offerid_offerinfo [ offerinstanceid ] = OfferInfo (
      _seller ,
			_buyer ,
			_target_erc1155_contract ,
			_itemid ,
      _paymeansaddress ,
			_amounttobuy ,
			_amounttopay ,
      _expiry ,
			true
		) ;
		_map_uuid_offerinfo [ _uuid ] = OfferInfo (
      _seller ,
			_buyer ,
			_target_erc1155_contract ,
			_itemid ,
      _paymeansaddress ,
			_amounttobuy ,
			_amounttopay ,
      _expiry ,
			true
		) ;
	}
	function get_offer_info ( bytes memory _offerid ) public returns ( OfferInfo memory ){
		return _map_offerid_offerinfo [ _offerid ] ;
	}
	function get_offer_info ( string memory _uuid ) public returns ( OfferInfo memory ) {
		return _map_uuid_offerinfo [ _uuid ] ;
	}
	function initoffermap ( string memory _uuid ) internal {
		_map_uuid_offerinfo [ _uuid ] = OfferInfo (address(0) , address(0) , address(0) , "",address(0) , 0,0,0 ,false );
	}
	function cancel_offer ( string memory _uuid ) public {
		OfferInfo memory offerinfo = _map_uuid_offerinfo [ _uuid ] ;
		if (offerinfo._active){}
		else {revert("ERR() invalid offer id");}		
		require ( msg.sender == offerinfo._buyer , "ERR() not privileged");
		makepayment( offerinfo._paymeansaddress
			, offerinfo._amounttopay
			, offerinfo._buyer
		) ;
/** 	if ( offerinfo._paymeansaddress == address(0)){
			payable (offerinfo._buyer).call { value : offerinfo._amounttopay } ("");
		} else {
			IERC20( _paymeansaddress ).transfer ( offerinfo._buyer , offerinfo._amounttopay ) ;
		} */
//		_map_uuid_offerinfo [ _uuid ] = OfferInfo (address(0) , address(0) , address(0) , "",0,0,false );
		initoffermap ( _uuid ) ;
	}
	function settle_offer ( string memory _uuid ) public {
		OfferInfo memory offerinfo = _map_uuid_offerinfo [ _uuid ] ;
		if ( offerinfo._active ){}
		else {revert("ERR() invalid offer"); }
		if ( offerinfo._expiry > block.timestamp ){}
		else {			initoffermap( _uuid ); // this func has side effect of deleting offers that are expired
		}
		uint256 tokenid = IERC1155( offerinfo._target_erc1155_contract )._itemhash ( offerinfo._itemid );
		IERC1155( offerinfo._target_erc1155_contract ).safeTransferFrom ( offerinfo._seller , offerinfo._buyer , tokenid , offerinfo._amounttobuy , "0x00" );
		makepayment ( offerinfo._paymeansaddress
			, offerinfo._amounttopay
			, offerinfo._seller
		) ;
		initoffermap( _uuid ) ;
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
/** 	function mint_and_offer ( 예치금을 지불하여 고정가 구매를 리스팅합니다. 민팅이 되어있지 않을 경우, 첫 오퍼러가 민팅을 합니다. 인자에 uuid를 통해 오퍼 인스턴스를 생성합니다.)
Get_offer_info (mint_and_offer 를 통해 등록된 offer 인스턴스를 확인합니다.)
Cancel_offer ( 오퍼를 철회합니다. 예치금을 돌려받습니다.)
Settle_offer ( 토큰 소유자만 접근할 수 있으며, 오퍼 가격을 수락하여 판매를 진행합니다.)
Withdraw (컨트랙트에 보관 중이던 토큰을 관리자 지갑 주소로 인출합니다.)
*/
