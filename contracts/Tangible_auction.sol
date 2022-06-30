pragma solidity ^0.8.0;
import "./Interfaces/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/IVerify-signature.sol" ;
import "./Interfaces/IERC1155.sol";
import "./Interfaces/ISaleInfo.sol";
import "./utils/Signing_admins.sol";
//import "hardhat/console.sol";
import "./Interfaces/IAdmin_nft.sol";

interface Interface_to_vault {
	enum SEND_TYPES {
			BID_DUTCH_BULK
		, BID_DUTCH_PIECES
		, BID_ENGLISH

		, ADMIN_FEE_SPOT
		, ADMIN_FEE_AUCTION_DUTCH_PIECES
		, ADMIN_FEE_AUCTION_DUTCH_BULK
		, ADMIN_FEE_AUCTION_ENGLISH

		, REFERER_FEE_DEPOSIT
		, AUTHOR_ROYALTY_DEPOSIT 
	}
	event DepositToVault (
			address _from
		, uint256 _amount
		, uint256 _type
		, address _to //		, uint256 _tokenid_or_batchid
	) ;
	event PaidFee (
			address _from
		, uint256 _amount
		, uint256 _type
		, address _to //		, uint256 _tokenid_or_batchid
	);
}

contract TangibleAuction is ERC1155MockReceiver , SaleInfo , Ownable , Signing_admins {
	mapping ( string => Sale_info ) public _map_auction_info ;
	mapping ( string => Pay_info ) public _map_bid_info ;
	mapping (string => bool) public _map_uuid_issue;
	address public _verify_signature_lib ;
	address public _admincontract;
	constructor ( address __verify_signature_lib, address __admincontract ) {
		_verify_signature_lib = __verify_signature_lib ;
		_admincontract = __admincontract;
	}
	function makePay(
		address _paymentAddress,
		uint256 _amount,
		address _from,
		address _to
	) internal {
		if(_paymentAddress == address(0)){
			//If native token e.g. ETH
			//payable(_to).call {value: _amount} ("");
			if(address(this)==_to){}
			else{
			payable(_to).call {value: _amount} ("");
			}
		}else{
			//Token
			IERC20(_paymentAddress).approve(address(this), _amount);
			IERC20(_paymentAddress).transferFrom(_from, _to, _amount);
		}
	}

	function set_with_admin_privilege ( string memory _uuid
		, Sale_info memory saleinfo
		, Pay_info memory payinfo
	 ) public {
		 require ( _signing_admins[ msg.sender ] , "ERR() not privileged" );		 
		_map_auction_info [ _uuid ] = saleinfo ;
		_map_bid_info[ _uuid ] = payinfo ;
	}
	function verify_done_delivery_signature ( string memory _uuid 
		, Signature memory _sig_done_delivery 
		, address _signing_admin
	) public returns ( bool ) {
		bytes memory data = abi.encodePacked ( 'Done delivery' , _uuid );
		bytes32 datahash = keccak256 ( data ) ;
		address recoveredaddress = IVerify_signature( _verify_signature_lib ).recoverSigner ( datahash , _sig_done_delivery._signature );
		return recoveredaddress == _signing_admin ;
	}
	function mint_and_bid (
			Mint_info memory mintinfo
		, Signature memory mintsignature
		, Sale_info memory saleinfo
		, Signature memory salesignature
		, Pay_info memory _payinfo
		//, string memory _uuid
	) public payable returns ( uint ) {
		/***** mint as usual */
		uint256 tokenid = IERC1155 ( mintinfo._target_erc1155_contract )._itemhash_tokenid ( mintinfo._itemid ) ;
		string memory _uuid = saleinfo._uuid;
		if ( tokenid == 0 ){
			tokenid = IERC1155 ( mintinfo._target_erc1155_contract ).mint ( 
					mintinfo._author
				, mintinfo._itemid
				, mintinfo.revealedhash
				, mintinfo._amounttomint
				, mintinfo._author_royalty
				, mintinfo._decimals
				, "0x00"
			) ;
		} // Sales_info saleinfo = _map_sales_info [ _saleid ];
		/******* validates */
		_payinfo._tokenid = tokenid;
		saleinfo._tokenid = tokenid;
		if ( saleinfo._status ) {	} 
		else {revert ("ERR() sale info not found"); }
		//if ( msg.value >= saleinfo._offerprice ){}
		//else {revert ("ERR() price not met");}
		if ( saleinfo._expiry < block.timestamp ){ revert("ERR() sale expired"); }
		else {}
		Pay_info memory preBidInfo;// = _map_bid_info [ _uuid ];
		if (_map_auction_info [ _uuid ]._status){
			//Checks if there's auction info
			preBidInfo = _map_bid_info[_uuid];
			if(preBidInfo._status){//Checks if there's bid info
				require(_payinfo._amounttopay > preBidInfo._amounttopay, "ERR():: lower than previous price.");
				//Return pre bidder
				if (saleinfo._paymeansaddress == address(0)){//MATIC
					require(msg.value >= _payinfo._amounttopay, "ERR():: amount doesn't match" );
					//If enough value, return eth to previous bidder
					makePay(address(0), preBidInfo._amounttopay, address(this), preBidInfo._buyer);
				}else{//Token (WETH)
					//Receives Token
					makePay(saleinfo._paymeansaddress, _payinfo._amounttopay, msg.sender, address(this));
					//Pay back to prev bidder
					makePay(saleinfo._paymeansaddress, preBidInfo._amounttopay, address(this), preBidInfo._buyer);
				}
				//Done with payment

				_map_bid_info[_uuid] = _payinfo;
			}
		}else{
			//IERC1155(mintinfo._target_erc1155_contract).safeTransferFrom(saleinfo._seller, address(this), tokenid, saleinfo._amounttosell, "0x00");
			//console.log("BBALANCE:::: %s", IERC1155(mintinfo._target_erc1155_contract).balanceOf(address(this), tokenid));
			makePay(saleinfo._paymeansaddress, _payinfo._amounttopay, msg.sender, address(this));
			_map_auction_info[_uuid] = saleinfo;
			_map_bid_info[_uuid] = _payinfo;
		}
		IERC1155(mintinfo._target_erc1155_contract).safeTransferFrom(saleinfo._seller, address(this), tokenid, saleinfo._amounttosell, "0x00");
		if(saleinfo._expiry>block.timestamp) {
			if(saleinfo._expiry-block.timestamp <= 10 minutes){
				_map_auction_info[_uuid]._expiry = block.timestamp + 10 minutes; 
				return _map_auction_info[_uuid]._expiry;
			}else{
				return 1;
			}
		}else{
			revert("ERR():: not right time for bidding");
		}
		
	}
	event Settle (
		address _buyer ,
		address _seller ,
		address _target_contract ,
		uint256 _itemid ,
		uint256 _tokenid ,
		address _settler
	);

	// function settle_auction(
	// 	string memory _uuid
	// ) public {
	// 	Sale_info memory auctioninfo = _map_auction_info [_uuid];
	// 	Pay_info memory bidinfo = _map_bid_info[_uuid];
	// 	require(auctioninfo._expiry<block.timestamp, "ERR() Expiry not met");
	// }

	function settle ( //		bytes32 _saleid
//			Signature _sig_init_delivery		, 
		//	Signature memory _sig_done_delivery // 
		//, address _signing_admin
		 string memory _uuid
	) public {
		/***** verify sig */
		//if ( _signing_admins[ _signing_admin ] ){}
		//else { revert ("ERR() signer invalid") ; }
		//if ( verify_done_delivery_signature ( _uuid , _sig_done_delivery , _signing_admin ) ){}
		//else {}
		/****** payments */
		Sale_info memory saleinfo = _map_auction_info [ _uuid ];
		Pay_info memory bidinfo = _map_bid_info[_uuid];

		if ( saleinfo._status ) {	} 
		else {revert ("ERR() sale info not found"); }
		Pay_info memory payinfo = _map_bid_info [ _uuid ] ;
		if ( payinfo._status  ){}
		else { revert("ERR() pay info not found");} // 		address seller = saleinfo._seller ;
		//payable ( saleinfo._seller ).transfer(saleinfo._offerprice);//.call {value : saleinfo._offerprice } (""); //		address buyer = payinfo._buyer ;
		//makePay(saleinfo._paymeansaddress, bidinfo._amounttopay, address(this), bidinfo._buyer);
		if(IERC1155(saleinfo._target_erc1155_contract)._tokenid_isclaimed(saleinfo._tokenid) == true){//ESCROW

			//revert("ERR() Seller cannot finishes the transaction during escrow");
			IERC1155( saleinfo._target_erc1155_contract ).safeTransferFrom ( address(this)
				, payinfo._buyer
				, saleinfo._tokenid
				, saleinfo._amounttosell
				, "0x00"
			) ;
		} else { //NFT
			feepayer(saleinfo._target_erc1155_contract, saleinfo._paymeansaddress, saleinfo._tokenid, payinfo._buyer, saleinfo._seller, payinfo._amounttopay, "TRADE_FEE");
			IERC1155( saleinfo._target_erc1155_contract ).safeTransferFrom ( address(this)
				, payinfo._buyer
				, saleinfo._tokenid
				, saleinfo._amounttosell
				, "0x00"
			) ;
			_map_bid_info[ _uuid]._status = false ;
			_map_auction_info[ _uuid]._status=false ;
		}
//		emit Settle ( payinfo._buyer , seller , saleinfo._target_erc1155_contract , saleinfo._itemid , saleinfo._tokenid , msg.sender );
	}

	function cancel_auction (
		string memory _uuid
	) public {

	}

	function expirycheck( string memory _uuid) public view returns(uint){
		return _map_auction_info[_uuid]._expiry;
	}

	function settle_escrow (
		string memory _uuid
	) public{

	}

	function payment(address _paymentaddress, address _from, address _to, uint256 _amount) internal {
		if(_paymentaddress == address(0)){
			//Native transfer
			payable(_to).call {value: _amount} ("");
		}else{
				//Token transfer
				if(_from ==address(this)){
					IERC20( _paymentaddress).transfer(_to , _amount);
				}else{
					IERC20( _paymentaddress).transferFrom( _from , _to , _amount);
				}
		}
	}

	function feepayer(
		address _target_erc1155_contract,
		address _paymentaddress,
		uint256 _tokenid,
		address _buyer,
		address _seller,
		uint256 _amounttopay,
		string memory _type
	) internal {
		uint256 remaining_amount = _amounttopay;
		uint256 admin_fee_rate = IAdmin_nft(_admincontract)._action_str_fees(_type);
		uint256 admin_fee_amount = remaining_amount * admin_fee_rate / 10000 ;
		address vault_contract = IAdmin_nft(_admincontract)._vault();
		uint256 author_royalty_rate = IERC1155(_target_erc1155_contract)._author_royalty(_tokenid);
		uint256 author_royalty_amount = _amounttopay * author_royalty_rate /10000;
		address author = IERC1155(_target_erc1155_contract)._author (_tokenid);
		require(remaining_amount>(admin_fee_amount + author_royalty_amount), "ERR() WRONG FEE TAKER");
		//ADMIN FEE
		if(admin_fee_amount>0 && IAdmin_nft(_admincontract)._action_str_fees_bool(_type)){
			if(vault_contract == address(0)){
				revert("ERR() INVALID VAULT ADDRESS");
			}
			payment(_paymentaddress, _buyer, vault_contract, admin_fee_amount);
			remaining_amount-=admin_fee_amount;
		}
		/* ROYALTY */
		if(author_royalty_amount>0 && author != msg.sender){
			payment(_paymentaddress, _buyer, author, author_royalty_amount);
			remaining_amount -= author_royalty_amount;
		}
		/*TRANSFER TO SELLER*/
		payment(_paymentaddress, _buyer, _seller, remaining_amount);
	}

	function claim_issue (string memory _uuid, bool value)public{
		Sale_info memory saleinfo = _map_auction_info [ _uuid ];
		Pay_info memory payinfo = _map_bid_info [_uuid];
		require(payinfo._buyer == msg.sender, "FIXED ERR() ONLY BUYER CAN ACCESS");
		// if(saleinfo._expiry + 7 days < block.timestamp){
		// 	revert("FIXED ERR() CANNOT CLAIM ISSUE AFTER 7 days");
		// }
		_map_uuid_issue[_uuid] = value;
	}

	function cancel_escrow ( string memory _uuid)public{
		Sale_info memory saleinfo = _map_auction_info[_uuid];
		Pay_info memory payinfo = _map_bid_info [_uuid];
		if(_map_uuid_issue[_uuid] == true){
			if(msg.sender == saleinfo._seller){
				IERC1155( saleinfo._target_erc1155_contract ).safeTransferFrom ( address (this)
				, saleinfo._seller
				, payinfo._tokenid
				, saleinfo._amounttosell
				, "0x00"
				);
				payment(saleinfo._paymeansaddress, address(this), saleinfo._seller, payinfo._amounttopay);
			}
		}
	}
}