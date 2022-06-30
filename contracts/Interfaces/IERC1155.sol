contract CommonConstants {
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
} // Contract to test safe transfer behavior.
interface IERC1155 {
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event URI(string value, uint256 indexed id);

    function _INVALID_TOKEN_ID_() external view returns (uint256);

    function _acting_contracts(address) external view returns (bool);

    function _admincontract() external view returns (address);

    function _amounts(uint256) external view returns (uint256);

    function _author(uint256) external view returns (address);

    function _author_royalty(uint256) external view returns (uint256);

    function _balances(uint256, address) external view returns (uint256);

    function _contractowner() external view returns (address);

    function _decimals(uint256) external view returns (uint256);

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function _itemhash_copycount(string memory) external view returns (uint256);

    function _itemhash_tokenid(string memory) external view returns (uint256);

    function _operatorApprovals(address, address) external view returns (bool);

    function _owner() external view returns (address);

    function _owners(uint256 _tokenid) external view returns (address);

    function _token_id_global() external view returns (uint256);

    function _tokenid_isclaimed(uint256) view external returns (bool);

    function _tokenid_isfrozen(uint256) external view returns (bool);

    function _tokenid_itemhash(uint256) external view returns (string memory);

    function _tokenid_revealed_itemhash(uint256)
        external
        view
        returns (string memory);

    function _uri() external view returns (string memory);

    function _user_black_white_list_registry() external view returns (address);

    function _user_proxy_registry() external view returns (address);

    function _version() external view returns (string memory);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function mint(
        address _to,
        string memory _itemhash,
        string memory _revealedhash,
        uint256 amount,
        uint256 __author_royalty,
        uint256 __decimals,
        bytes memory data
    ) external returns (uint256);

    function mintBatch(
        address to,
        string[] memory _itemhashes,
        string[] memory _revealedhashes,
        uint256[] memory amounts,
        uint256[] memory __author_royalty,
        uint256[] memory __decimals,
        bytes memory data
    ) external returns (uint256[] memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function set_acting_contracts(address _address, bool _status) external;

    function set_tokenid_claim(address from, uint256 tokenid) external;

    function set_tokenid_freeze(uint256 tokenid, bool status) external;

    function set_user_proxy_registry(address _address) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function transfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function transferOwnership(address newOwner) external;

    function uri(uint256) external view returns (string memory);
}

contract ERC1155MockReceiver is // ERC1155TokenReceiver,
 CommonConstants {
	// Keep values from last received contract.
	bool public shouldReject;
	bytes public lastData;
	address public lastOperator;
	address public lastFrom;
	uint256 public lastId;
	uint256 public lastValue;
	function setShouldReject(bool _value) public {
		shouldReject = _value;
	}
	function onERC1155Received(address _operator
		, address _from
		, uint256 _id
		, uint256 _value
		, bytes calldata _data) 
	external returns(bytes4) {
		lastOperator = _operator;
		lastFrom = _from;
		lastId = _id;
		lastValue = _value;
		lastData = _data;
		if ( shouldReject == true) {
			revert("onERC1155Received: transfer not accepted");
		} else {
				return ERC1155_ACCEPTED;
		}
	}
	function onERC1155BatchReceived(address _operator
		, address _from
		, uint256[] calldata _ids
		, uint256[] calldata _values
		, bytes calldata _data) 
	external returns(bytes4) {
		lastOperator = _operator;
		lastFrom = _from;
		lastId = _ids[0];
		lastValue = _values[0];
		lastData = _data;
		if (shouldReject == true) {
			revert("onERC1155BatchReceived: transfer not accepted");
		} else {
			return ERC1155_BATCH_ACCEPTED;
		}
	}	// ERC165 interface support
	function supportsInterface(bytes4 interfaceID) external view returns (bool) {
		return  interfaceID == 0x01ffc9a7 ||    // ERC165
						interfaceID == 0x4e2312e0;      // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
	}
}
