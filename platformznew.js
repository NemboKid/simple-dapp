const PlatformzNew = artifacts.require("./PlatformzNew.sol");
var assert = require('assert')
let contractInstance;
const Web3 = require('web3');

//const accounts = getWeb3.eth.getAccounts();

contract('PlatformzNew', (accounts) => {
   beforeEach(async () => {
      contractInstance = await PlatformzNew.deployed()
   })

   it('Contract deployer becomes owner', async () => {
      const isOwner = await contractInstance.owner.call();
      const isDeployer = await accounts[0];

      assert.equal(isOwner, isDeployer, "they should be the same")
    });


    it('Add Developer', async () => {
      const developer1 = accounts[1];
      const weight1 = 100;
      isOwner = accounts[0];
      await contractInstance.addDeveloper(developer1, weight1, {from:isOwner})
      const checkDevs = await contractInstance.numberOfDevs.call()
      const checkWeight = await contractInstance.weightGuard.call()
      assert.equal(checkDevs == 1, checkWeight == 100, "Didn't add developer properly")
    })

    it('Add Admin', async () => {
      isOwner = accounts[0];
      const admin1 = accounts[2];
      const checker = await contractInstance.addAdmin(admin1, {from: isOwner})
      assert(checker)
    })


    it('Start Contract', async () => {
      //const amount = web3.utils.toWei('2', 'ether');
      //const numberOfWeeks = 4;
      isOwner = accounts[0];
      await contractInstance.startWork(4, {
        from: accounts[0],
        value: 100
      });
      const isTrue = await contractInstance.contractActive.call()
      assert.equal(isTrue, true)
    })

    it('Accept Step', async () => {
      //const amount = web3.utils.toWei('2', 'ether');
      //const numberOfWeeks = 4;
      isOwner = accounts[0];
      await contractInstance.stepAccept( {from: isOwner});
      const stepCounter = await contractInstance.stepCount.call()
      assert.equal(stepCounter, 1)
    })


    it('Withdraw Money', async () => {
      const developer1 = accounts[1];
      isOwner = accounts[0];
      await contractInstance.withdrawal( {from: developer1});
      const balanceContract = await contractInstance.checkBalance({from: isOwner})
      const depositSum = await contractInstance.depositAmount({from: isOwner})
      assert.equal(balanceContract, depositSum*0.75)
    })


    it('Extend Deadline', async () => {
      const developer1 = accounts[1];
      isOwner = accounts[0];
      const oldTime = await contractInstance.contractEndTime.call()
      await contractInstance.extendDeadline(4, {from: isOwner});
      const newTime = await contractInstance.contractEndTime.call();
      assert(newTime.toNumber() > oldTime.toNumber())
      console.log(oldTime.toNumber())
      console.log(newTime.toNumber())
    })

})
