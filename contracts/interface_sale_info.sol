interface Sale_info {
	struct Mint_info {
		address _target_erc1155_contract;
		string _itemid ;
		uint256 _tokenid ; //		address _seller ;
		address _author ;
		uint256 _amounttomint ;
		uint256 _author_royalty ;
		uint256 _decimals ;
		string _uuid ;
	}
	struct Sale_info {
		address _target_erc1155_contract ;
		string _itemid ;
		uint256 _tokenid ;
		address _author ;
		uint256 _amounttosell ;
		address _paymeansaddress ;
		uint256 _offerprice ;
		uint256 _starting_time ;
		uint256 _expiry ;
		address _seller ;
		bool _status ;
		string _uuid ;
	}
	struct Pay_info {
		address _buyer ;
		string _itemid ;
		uint256 _tokenid ;
		uint256 _amounttopay ;
		bool _status ;
		string _uuid ;
	}
	struct Signature {
//		bytes32 _signature ;
		bytes _signature ;
		bytes32 _datahash;
	}
	struct Offer_info {
		address _seller ;
		address _buyer ;
		address _target_erc1155_contract ;
		string _itemid ;
		uint256 _tokenid ;
    address _paymeansaddress ;
		uint256 _amounttobuy ;
		uint256 _amounttopay ;
    uint256 _expiry ;
		bool _active ;
		bool _status ;
	}

}
