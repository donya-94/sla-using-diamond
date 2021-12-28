/* global describe it before ethers */




Web3 = require('web3');
const web3 = new Web3("http://localhost:8545");

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')

const { assert } = require('chai')

describe('DiamondTest', async function () {
  let diamondAddress
  let diamondInit
  let deployDiamondVar
  let diamondCutFacet
  let diamondLoupeFacet
  let ownershipFacet
  let witnessPoolFacet
  let sortitionFacet
  let slaInitializing
  let tx
  let receipt
  let result
  const addresses = []
  

  before(async function () {
    deployDiamondVar = await deployDiamond()
    diamondAddress = deployDiamondVar.diamond
    diamondInit = deployDiamondVar.diamondInit
    console.log('DiamondAddress is: ', diamondAddress)
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
    witnessPoolFacet = await ethers.getContractAt('WitnessPoolFacet', diamondAddress)
    sortitionFacet = await ethers.getContractAt('SortitionFacet', diamondAddress)
    slaInitializing = await ethers.getContractAt('SLAInitializing', diamondAddress)
    // diamondInit = deployDiamondVar.diamondInit
  })

  it('print DiamondInit and functionCall', async()=>{

    // console.log('DiamondInit deployed:', diamondInit)

    
    // console.log('DiamondInit deployed:', deployDiamondVar.functionCall)
  })

  it('should have six facets -- call to facetAddresses function', async () => {
    for (const address of await diamondLoupeFacet.facetAddresses()) {
      addresses.push(address)
    }

    assert.equal(addresses.length, 6)
  })

  it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
    let selectors = getSelectors(diamondCutFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(diamondLoupeFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(ownershipFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(witnessPoolFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(sortitionFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[4])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(slaInitializing)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[5])
    assert.sameMembers(result, selectors)
  })

  // it('selectors should be associated to facets correctly -- multiple calls to facetAddress function', async () => {
  //   assert.equal(
  //     addresses[0],
  //     await diamondLoupeFacet.facetAddress('0x1f931c1c')
  //   )
  //   assert.equal(
  //     addresses[1],
  //     await diamondLoupeFacet.facetAddress('0xcdffacc6')
  //   )
  //   assert.equal(
  //     addresses[1],
  //     await diamondLoupeFacet.facetAddress('0x01ffc9a7')
  //   )
  //   assert.equal(
  //     addresses[2],
  //     await diamondLoupeFacet.facetAddress('0xf2fde38b')

  //   )
  // })

//****************  Test WitnessPool **************************** */

   it('testing WitnessPool', async() => {

    console.log('I am in witness scope' );

    let accounts = [];
    accounts = [owner, nothing, customer, wit1, wit2, wit3, wit4, wit5, wit6, provider] = await ethers.getSigners();
    console.log('Provider address is: ',provider.address);
    console.log('Owner address is: ',owner.address);

    await witnessPoolFacet.connect(provider).registerProvider();
    console.log( await web3.eth.getBalance(provider.address));

    await witnessPoolFacet.connect(wit1).register();
    await witnessPoolFacet.connect(wit2).register();
    await witnessPoolFacet.connect(wit3).register();
    await witnessPoolFacet.connect(wit4).register();
    await witnessPoolFacet.connect(wit5).register();
    await witnessPoolFacet.connect(wit6).register();

    // await slaInitializing.connect(provider).setTime();
    // await slaInitializing.connect(provider).returnTime();

    // await witnessPoolFacet.connect(provider).returnValue();

  //   //run cloudSLA***********************************************
    const CloudSLA = await ethers.getContractFactory('CloudSLA');
    const cloudSLA = await CloudSLA.connect(provider).deploy();
    // console.log("provider +++++++++++++++++++++++++++",cloudSLA);

    await cloudSLA.deployed();

    

  //   /*  Initializing the variable of SLA ******************** */
    // const SLAInitializing = await ethers.getContractFactory('SLAInitializing');
    // const slaInitializing = await SLAInitializing.connect(provider).deploy();
    // await slaInitializing.deployed();

    // const DiamondInit = await ethers.getContractFactory('DiamondInit')
    // const diamondInit = await DiamondInit.deploy()
    // await diamondInit.deployed()

    let selectors = getSelectors(diamondCutFacet);

    const cut = [];
    // for SLA
    cut.push({facetAddress: cloudSLA.address, 
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(cloudSLA)});

      // for Initiate variables
      // cut.push({facetAddress: slaInitializing.address, 
      //   action: FacetCutAction.Add,
      //   functionSelectors: getSelectors(slaInitializing)});

        // console.log('Diamond Cut:', cut)

    const diamondCut = await ethers.getContractAt('IDiamondCut', diamondAddress)
    // call to init function
    console.log('before functionCall');
    // console.log('interface_+_+_+_+_+_+_+_+_+_+_+_+_+_', diamondInit.connect(provider).interface.encodeFunctionData('init1',[customer.address, cloudSLA.address]) );
    const functionCall = diamondInit.interface.encodeFunctionData('init1',[provider.address, customer.address, cloudSLA.address]);
    
    // const newFunctionCall = functionCall.slice(0,10);
    console.log('functionCall in test.js is:' , functionCall);
    await diamondCut.diamondCut(cut , diamondInit.address, functionCall);
    console.log('after await functionCall');

    sla = await ethers.getContractAt('CloudSLA', diamondAddress);

    // initializing = await ethers.getContractAt('SLAInitializing', diamondAddress);
 
    let a = [];
    a = await diamondLoupeFacet.facetAddresses();
    addresses.push(a[6]);
    // addresses.push(a[6]);
    
    /* The 3 commands below are for checking same function selector of facet ***** */
    // selectors = getSelectors(sla);
    // result = await diamondLoupeFacet.facetFunctionSelectors(addresses[6]);
    // assert.sameMembers(result, selectors);
    
    // /* The 3 commands below are for checking same function selector of facet ***** */
    // selectors = getSelectors(initializing);
    // result = await diamondLoupeFacet.facetFunctionSelectors(addresses[6]);
    // assert.sameMembers(result, selectors);



    // //*   Request for sortition************************************ */

    await sla.connect(provider).request();
    // console.log("cloudSLA is: ", cloudSLA.address);
    
    
    let tx = await sla.connect(provider).sortition(3);
    let receipt = await tx.wait();
    const temp = receipt.events?.filter((x) => {return x.event == "WitnessSelected"});
    // console.log("events are :", temp[1].args[0]);

    switch (temp[0].args[0]) {
      case wit1.address: await sla.connect(wit1).confirm(); break;
      case wit2.address: await sla.connect(wit2).confirm(); break;
      case wit3.address: await sla.connect(wit3).confirm(); break;
      case wit4.address: await sla.connect(wit4).confirm(); break;
      case wit5.address: await sla.connect(wit5).confirm(); break;
      case wit6.address: await sla.connect(wit6).confirm(); break; 
      default: break;
    }

    switch (temp[1].args[0]) {
      case wit1.address: await sla.connect(wit1).confirm(); break;
      case wit2.address: await sla.connect(wit2).confirm(); break;
      case wit3.address: await sla.connect(wit3).confirm(); break;
      case wit4.address: await sla.connect(wit4).confirm(); break;
      case wit5.address: await sla.connect(wit5).confirm(); break;
      case wit6.address: await sla.connect(wit6).confirm(); break; 
      default: break;
    }

    switch (temp[2].args[0]) {
      case wit1.address: await sla.connect(wit1).confirm(); break;
      case wit2.address: await sla.connect(wit2).confirm(); break;
      case wit3.address: await sla.connect(wit3).confirm(); break;
      case wit4.address: await sla.connect(wit4).confirm(); break;
      case wit5.address: await sla.connect(wit5).confirm(); break;
      case wit6.address: await sla.connect(wit6).confirm(); break; 
      default: break;
    }


    // let witnessArray  = [];
    // console.log("witness in event is: ", temp.map( function(obj){
    //   obj._who
    // }));
    // if (temp.filter(obj => {
    //     return obj.who == wit1.address
    //   }))
    //   sla.connect(wit1).confirm();



    // await initializing.connect(provider).setBlkNeeded(2);

  })

  

//**************************************************************** */


  // it('should add test1 functions', async () => {
  //   const Test1Facet = await ethers.getContractFactory('Test1Facet')
  //   const test1Facet = await Test1Facet.deploy()
  //   await test1Facet.deployed()
  //   addresses.push(test1Facet.address)
  //   const selectors = getSelectors(test1Facet).remove(['supportsInterface(bytes4)'])
  //   tx = await diamondCutFacet.diamondCut(
  //     [{
  //       facetAddress: test1Facet.address,
  //       action: FacetCutAction.Add,
  //       functionSelectors: selectors
  //     }],
  //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
  //   receipt = await tx.wait()
  //   if (!receipt.status) {
  //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
  //   }
  //   result = await diamondLoupeFacet.facetFunctionSelectors(test1Facet.address)
  //   assert.sameMembers(result, selectors)
  // })

  // it('should test function call', async () => {
  //   const test1Facet = await ethers.getContractAt('Test1Facet', diamondAddress)
  //   await test1Facet.test1Func10()
  // })

  // it('should replace supportsInterface function', async () => {
  //   const Test1Facet = await ethers.getContractFactory('Test1Facet')
  //   const selectors = getSelectors(Test1Facet).get(['supportsInterface(bytes4)'])
  //   const testFacetAddress = addresses[3]
  //   tx = await diamondCutFacet.diamondCut(
  //     [{
  //       facetAddress: testFacetAddress,
  //       action: FacetCutAction.Replace,
  //       functionSelectors: selectors
  //     }],
  //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
  //   receipt = await tx.wait()
  //   if (!receipt.status) {
  //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
  //   }
  //   result = await diamondLoupeFacet.facetFunctionSelectors(testFacetAddress)
  //   assert.sameMembers(result, getSelectors(Test1Facet))
  // })

  // it('should add test2 functions', async () => {
  //   const Test2Facet = await ethers.getContractFactory('Test2Facet')
  //   const test2Facet = await Test2Facet.deploy()
  //   await test2Facet.deployed()
  //   addresses.push(test2Facet.address)
  //   const selectors = getSelectors(test2Facet)
  //   tx = await diamondCutFacet.diamondCut(
  //     [{
  //       facetAddress: test2Facet.address,
  //       action: FacetCutAction.Add,
  //       functionSelectors: selectors
  //     }],
  //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
  //   receipt = await tx.wait()
  //   if (!receipt.status) {
  //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
  //   }
  //   result = await diamondLoupeFacet.facetFunctionSelectors(test2Facet.address)
  //   assert.sameMembers(result, selectors)
  // })

  // it('should remove some test2 functions', async () => {
  //   const test2Facet = await ethers.getContractAt('Test2Facet', diamondAddress)
  //   const functionsToKeep = ['test2Func1()', 'test2Func5()', 'test2Func6()', 'test2Func19()', 'test2Func20()']
  //   const selectors = getSelectors(test2Facet).remove(functionsToKeep)
  //   tx = await diamondCutFacet.diamondCut(
  //     [{
  //       facetAddress: ethers.constants.AddressZero,
  //       action: FacetCutAction.Remove,
  //       functionSelectors: selectors
  //     }],
  //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
  //   receipt = await tx.wait()
  //   if (!receipt.status) {
  //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
  //   }
  //   result = await diamondLoupeFacet.facetFunctionSelectors(addresses[4])
  //   assert.sameMembers(result, getSelectors(test2Facet).get(functionsToKeep))
  // })

  // it('should remove some test1 functions', async () => {
  //   const test1Facet = await ethers.getContractAt('Test1Facet', diamondAddress)
  //   const functionsToKeep = ['test1Func2()', 'test1Func11()', 'test1Func12()']
  //   const selectors = getSelectors(test1Facet).remove(functionsToKeep)
  //   tx = await diamondCutFacet.diamondCut(
  //     [{
  //       facetAddress: ethers.constants.AddressZero,
  //       action: FacetCutAction.Remove,
  //       functionSelectors: selectors
  //     }],
  //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
  //   receipt = await tx.wait()
  //   if (!receipt.status) {
  //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
  //   }
  //   result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3])
  //   assert.sameMembers(result, getSelectors(test1Facet).get(functionsToKeep))
  // })

  // it('remove all functions and facets accept \'diamondCut\' and \'facets\'', async () => {
  //   let selectors = []
  //   let facets = await diamondLoupeFacet.facets()
  //   for (let i = 0; i < facets.length; i++) {
  //     selectors.push(...facets[i].functionSelectors)
  //   }
  //   selectors = removeSelectors(selectors, ['facets()', 'diamondCut(tuple(address,uint8,bytes4[])[],address,bytes)'])
  //   tx = await diamondCutFacet.diamondCut(
  //     [{
  //       facetAddress: ethers.constants.AddressZero,
  //       action: FacetCutAction.Remove,
  //       functionSelectors: selectors
  //     }],
  //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
  //   receipt = await tx.wait()
  //   if (!receipt.status) {
  //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
  //   }
  //   facets = await diamondLoupeFacet.facets()
  //   assert.equal(facets.length, 2)
  //   assert.equal(facets[0][0], addresses[0])
  //   assert.sameMembers(facets[0][1], ['0x1f931c1c'])
  //   assert.equal(facets[1][0], addresses[1])
  //   assert.sameMembers(facets[1][1], ['0x7a0ed627'])
  // })

  // it('add most functions and facets', async () => {
  //   const diamondLoupeFacetSelectors = getSelectors(diamondLoupeFacet).remove(['supportsInterface(bytes4)'])
  //   const Test1Facet = await ethers.getContractFactory('Test1Facet')
  //   const Test2Facet = await ethers.getContractFactory('Test2Facet')
  //   // Any number of functions from any number of facets can be added/replaced/removed in a
  //   // single transaction
  //   const cut = [
  //     {
  //       facetAddress: addresses[1],
  //       action: FacetCutAction.Add,
  //       functionSelectors: diamondLoupeFacetSelectors.remove(['facets()'])
  //     },
  //     {
  //       facetAddress: addresses[2],
  //       action: FacetCutAction.Add,
  //       functionSelectors: getSelectors(ownershipFacet)
  //     },
  //     {
  //       facetAddress: addresses[3],
  //       action: FacetCutAction.Add,
  //       functionSelectors: getSelectors(Test1Facet)
  //     },
  //     {
  //       facetAddress: addresses[4],
  //       action: FacetCutAction.Add,
  //       functionSelectors: getSelectors(Test2Facet)
  //     }
  //   ]
  //   tx = await diamondCutFacet.diamondCut(cut, ethers.constants.AddressZero, '0x', { gasLimit: 8000000 })
  //   receipt = await tx.wait()
  //   if (!receipt.status) {
  //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
  //   }
  //   const facets = await diamondLoupeFacet.facets()
  //   const facetAddresses = await diamondLoupeFacet.facetAddresses()
  //   assert.equal(facetAddresses.length, 5)
  //   assert.equal(facets.length, 5)
  //   assert.sameMembers(facetAddresses, addresses)
  //   assert.equal(facets[0][0], facetAddresses[0], 'first facet')
  //   assert.equal(facets[1][0], facetAddresses[1], 'second facet')
  //   assert.equal(facets[2][0], facetAddresses[2], 'third facet')
  //   assert.equal(facets[3][0], facetAddresses[3], 'fourth facet')
  //   assert.equal(facets[4][0], facetAddresses[4], 'fifth facet')
  //   assert.sameMembers(facets[findAddressPositionInFacets(addresses[0], facets)][1], getSelectors(diamondCutFacet))
  //   assert.sameMembers(facets[findAddressPositionInFacets(addresses[1], facets)][1], diamondLoupeFacetSelectors)
  //   assert.sameMembers(facets[findAddressPositionInFacets(addresses[2], facets)][1], getSelectors(ownershipFacet))
  //   assert.sameMembers(facets[findAddressPositionInFacets(addresses[3], facets)][1], getSelectors(Test1Facet))
  //   assert.sameMembers(facets[findAddressPositionInFacets(addresses[4], facets)][1], getSelectors(Test2Facet))
  // })
})
