contract Signing_admins {
	mapping ( address => bool ) public _signing_admins ;
	function set_signing_admin ( address _address , bool _status ) public {
		_signing_admins [ _address ] = _status ;
	}
	constructor () {}
}