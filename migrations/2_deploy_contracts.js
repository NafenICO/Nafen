var NafenToken = artifacts.require("./NafenToken.sol");
var PrivatePlacement = artifacts.require("./PrivatePlacement.sol");


module.exports = function(deployer) {
  deployer.deploy(NafenToken);
  deployer.deploy(PrivatePlacement);
};
