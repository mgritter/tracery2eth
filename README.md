# tracery2eth

This is a project to create a Tracery-to-Solidity compiler so that procedurally
generated content can be created on the Ethereum blockchain.

Current status: a hand-crafted example is working, translated from a Tracery
tutorial example.  It is running on the Rinkeby test chain, at address
0x024e724c30355326583ea41ef0e1ba6dd047e9aa

## Compilation and Running

You should have geth and solc installed.  The include SCons file will
call solc and generate a Javascript file in the build directory suitable
for import into geth:

```javascript
loadScript( "build/animal.js" )
```

You can then use the helper functions to either create your own version
of the contract, or access the existing one.  Example usage:

```javascript
c = getContract( "0x024e724c30355326583ea41ef0e1ba6dd047e9aa" )

// Local test of PCG (doesn't affect blockchain)
// You'll get the same animal every time because the RNG is seeded
// with block # and sender
c.testAnimal()

// Permanent creation of your very own, unique, PCG animal:
eth.defaultAccount = eth.accounts[0]
personal.unlockAccount( eth.defaultAccount, "yourpassword" )
c.createAnimal( 1, {gas:150000} )
// Wait for transaction to finish.
c.getMyAnimal()
```

Note that the default amount of gas won't be enough; about 150k should do.  (Yes, it's very expensive, about $0.12 in real money.)

Or, you can just import the .sol file into your favorite environment.

## Frequent Objections

#### This isn't the sort of thing the blockchain is meant for!

Yes, I agree.  It merely amuses me to have procedurally-generated
content living in the blockchain forever.

#### You should structure your smart contract differently!

It would make more sense to do PCG in a front-end (cheaply) and only use the
blockchain for claiming ownership.

This is not a project about making sense.  I feel it's more amusing
to have every miner executing my silly (and expensive) string-manipulation
functions.

