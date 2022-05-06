interface IVerify_signature {
	function prefixed (bytes32 hash) public pure returns (bytes32) ;
	function splitSignature (bytes memory _sig) public pure returns (uint8, bytes32, bytes32) ;
	function recoverSigner (bytes32 message, bytes memory _sig) public pure returns (address) ;
}
contract Verify_signature {
/*		function verify_done_delivery_signature ( string memory _uuid 
		, Signature _sig_done_delivery 
		, address _signing_admin
	) public {
		Sale_info saleinfo = _map_sale_info [ _uuid ] ;
		string data = encodePacked ( 'Done delivery' , _uuid );
		string datahash = keccak256 ( data ) ;
		address recoveredaddress = recoverSigner ( datahash , _sig_done_delivery._signature );
		return recoveredaddress == _signing_admin ;
	}
*/
	function prefixed (bytes32 hash) public pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Klaytn Signed Message:\n32", hash));
	}
	function splitSignature (bytes memory _sig) public pure returns (uint8, bytes32, bytes32) {
		require(_sig.length == 65);
		bytes32 r;
		bytes32 s;
		uint8 v;
		assembly {
			// first 32 bytes, after the length prefix
			r := mload(add(_sig, 32))
			// second 32 bytes
			s := mload(add(_sig, 64))
			// final byte (first byte of the next 32 bytes)
			v := byte(0, mload(add(_sig, 96)))
		}
		return (v, r, s);
	}
	function recoverSigner (bytes32 message, bytes memory _sig) public pure returns (address) {
		uint8 v;
		bytes32 r;
		bytes32 s;
		bytes32 dehashed_message;
		(dehashed_message) = prefixed(message);
		(v, r, s) = splitSignature(_sig);
		return ecrecover(dehashed_message, v, r, s);
	}
}
