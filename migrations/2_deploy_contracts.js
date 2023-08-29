var HealthChain = artifacts.require("HealthChain");

module.exports = async function(deployer){
    deployer.deploy(HealthChain);
}