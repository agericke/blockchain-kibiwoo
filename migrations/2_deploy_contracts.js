// Deploy all contracts that KibiwooOwnership contract imports
//var Ownable = artifacts.require("Ownable");
//var SafeMath = artifacts.require("SafeMath");
var KibiwooRegisterProducts = artifacts.require("KibiwooRegisterProducts");
var KibiwooManageProducts = artifacts.require("KibiwooManageProducts");
//var KibiwooHelperProducts = artifacts.require("KibiwooHelperProducts");
//var ERC721 = artifacts.require("ERC721");
//var ERC165 = artifacts.require("ERC165");
//var KibiwooOwnership = artifacts.require("KibiwooOwnership");

module.exports = function(deployer) {
	//deployer.deploy(Ownable);
	//deployer.deploy(SafeMath);
	//deployer.link(SafeMath, KibiwooRegisterProducts);
	deployer.deploy(KibiwooRegisterProducts);
	deployer.deploy(KibiwooManageProducts);
	//deployer.deploy(KibiwooHelperProducts);
 	//deployer.deploy(ERC721);
	//deployer.deploy(ERC165);
	//deployer.deploy(KibiwooOwnership);
};