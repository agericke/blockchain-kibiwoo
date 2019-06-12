// Deploy all contracts that KibiwooOwnership contract imports
var Ownable = artifacts.require("Ownable");
var SafeMath = artifacts.require("SafeMath");
var Counters = artifacts.require("Counters");
var Address = artifacts.require("Address");
var KibiwooRegisterProducts = artifacts.require("KibiwooRegisterProducts");
var KibiwooManageProducts = artifacts.require("KibiwooManageProducts");
var KibiwooHelperProducts = artifacts.require("KibiwooHelperProducts");
var ERC165 = artifacts.require("ERC165");
var KibiwooOwnership = artifacts.require("KibiwooOwnership");

module.exports = function(deployer) {
	//deployer.deploy(Ownable);
	deployer.deploy(SafeMath);
	deployer.link(
		SafeMath, 
		[
			Counters, 
			KibiwooRegisterProducts, 
			KibiwooManageProducts, 
			KibiwooHelperProducts, 
			KibiwooOwnership
		]
	);
	deployer.deploy(Counters);
	deployer.link(
		Counters, 
		[
			KibiwooRegisterProducts, 
			KibiwooManageProducts, 
			KibiwooHelperProducts,
			KibiwooOwnership
		]
	);
	deployer.deploy(KibiwooRegisterProducts);
	deployer.deploy(KibiwooManageProducts);
	deployer.deploy(KibiwooHelperProducts);
	deployer.deploy(Address);
	deployer.link(Address, KibiwooOwnership);
	deployer.deploy(KibiwooOwnership);
};