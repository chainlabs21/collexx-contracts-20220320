contract CommonConstants {
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
} // Contract to test safe transfer behavior.
interface IERC1155  { // is IERC165
	function _acting_contracts ( address _address ) external view returns ( bool _status) ;
	function set_acting_contracts( address _address , bool _status ) external ;
	function safeTransferFrom (
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external ;
	function safeBatchTransferFrom (
		address from,
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external;
	function mint (
		address to, //		uint256 id,
		string memory _itemhash ,
		uint256 amount,
		uint256 __author_royalty ,
		uint256 __decimals ,
		bytes memory data
	) external returns ( uint256 );
	function mintBatch (
		address to, //			uint256[] memory ids,
		string [] memory _itemhashes ,
		uint256[] memory amounts,
		uint256 [] memory __author_royalty ,
		bytes memory data
	) external returns ( uint256 [] memory ) ;
	function burn (
		address from,
		uint256 id,
		uint256 amount
	)	external ;
	function burnBatch (
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) external ;
  event TransferSingle (
			address indexed operator
		, address indexed from
		, address indexed to
		, uint256 id
		, uint256 value ); /**     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.     */
  event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] values
  );
	function _itemhash_tokenid ( string memory  ) external view returns (uint256 ) ; // content id mapping ( string => uint256 ) public
	function _tokenid_itemhash ( uint256 ) external view returns ( string memory ) ; // mapping (uint256 => string ) public
	function _token_id_global () external view returns ( uint256 ) ;
	function _author_royalty ( uint256 ) external view  returns ( uint );
	event ApprovalForAll(address indexed account, address indexed operator, bool approved); /**     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to     * `approved`.     */
	event URI(string value, uint256 indexed id);     /**     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.     *     * If an {URI} ev ent was emitted for `id`, the standard     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value     * returned by {IERC1155MetadataURI-uri}.     */    
  function balanceOf(address account, uint256 id) external view returns (uint256); /**     * @dev Returns the amount of tokens of token type `id` owned by `account`.     *     * Requirements:     *     * - `account` cannot be the zero address.     */    
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)        external        view        returns (uint256[] memory); /**     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.     *     * Requirements:     *     * - `accounts` and `ids` must have the same length.     */    
  function setApprovalForAll(address operator, bool approved) external; /**     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,     *     * Emits an {ApprovalForAll} ev ent.     *     * Requirements:     *     * - `operator` cannot be the caller.     */    
  function isApprovedForAll(address account, address operator) external view returns (bool);		/**     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.     *     * See {setApprovalForAll}.     */
	function _author ( uint256 ) external view returns ( address ) ; //	mapping ( uint256=> address ) public _author ; // do struct if more than two
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
