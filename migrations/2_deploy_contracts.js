var NafenToken = artifacts.require("./NafenToken.sol");
var PrivatePlacement = artifacts.require("./PrivatePlacement.sol");


module.exports = function(deployer) {
  deployer.deploy(NafenToken).then(function() {
  return deployer.deploy(PrivatePlacement, NafenToken.address,accounts[0],Date.now(),180,Date.now()+240,180,Date.now()+480,180);
});
};
