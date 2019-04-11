pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./../contracts/KibiwooOwnership.sol";

contract TestKibiwoo {

	KibiwooOwnership kibiwoo = KibiwooOwnership(DeployedAddresses.KibiwooOwnership());

	uint expectedProductId = 17;

	address expectedOwner = address(this);

	function testUserCanRegisterProduct () public {
		
		uint returnedId = kibiwoo._registerProduct(expectedProductId, "Pedro", 1);

		Assert.equal(returnedId, expectedProductId, "Registration of product failed.");
	}

	function testGetOwnersAddressByProductID () public {
		
		address owner = kibiwoo._owners(expectedProductId);

		Assert.equal(owner, expectedOwner, "Owner of the expected product does not match.");
	}

	function testGetOwnerAdressByProductIdInArray() public {

		address[20] memory owners = kibiwoo.getOwners();

		Assert.equal(owners[expectedProductId], expectedOwner, "Owner of th expected product should be this contract");
	}
	
}