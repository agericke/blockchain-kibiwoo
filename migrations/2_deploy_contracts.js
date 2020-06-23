// Deploy all contracts that KibiwooOwnership contract imports
var Ownable = artifacts.require("Ownable");
var SafeMath = artifacts.require("SafeMath");
var Counters = artifacts.require("Counters");
var Address = artifacts.require("Address");
var TreeMap = artifacts.require("TreeMap");
var KibiwooRegisterProducts = artifacts.require("KibiwooRegisterProducts");
var KibiwooManageProducts = artifacts.require("KibiwooManageProducts");
var KibiwooHelperProducts = artifacts.require("KibiwooHelperProducts");
var ERC165 = artifacts.require("ERC165");
var KibiwooOwnership = artifacts.require("KibiwooOwnership");
var Kibiwoo = artifacts.require("Kibiwoo");
var BookingContract = artifacts.require("BookingContract");

module.exports = function(deployer) {
	//deployer.deploy(Ownable);
	deployer.deploy(SafeMath);
	deployer.link(
		SafeMath, 
		[
			Counters, 
			BookingContract,
			Kibiwoo, 
			KibiwooManageProducts, 
			KibiwooHelperProducts, 
			KibiwooOwnership
		]
	);
	deployer.deploy(Counters);
	deployer.link(
		Counters, 
		[
			Kibiwoo,
			BookingContract,
			KibiwooManageProducts, 
			KibiwooHelperProducts,
			KibiwooOwnership
		]
	);
	deployer.deploy(TreeMap);
	deployer.link(
		TreeMap,
		[
			BookingContract
		]
	);
	deployer.deploy(Kibiwoo,  "KibiwooProductsTFM", "KBW");
	//deployer.deploy(BookingContract,  1, 3600);
	/*deployer.deploy(KibiwooManageProducts);
	deployer.deploy(KibiwooHelperProducts);
	deployer.deploy(Address);
	deployer.link(Address, KibiwooOwnership);
	deployer.deploy(KibiwooOwnership);*/
};