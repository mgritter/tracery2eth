# tracery2eth

This is a project to create a Tracery-to-Solidity compiler so that procedurally
generated content can be created on the Ethereum blockchain.

Tracery can be found at http://tracery.io, or https://github.com/galaxykate/tracery.  Twitter bots based on tracery can be found at http://cheapbotsdonequick.com/

### Project status ###

Automatic compilation is working, at least for a few Tracery
tutorial examples.

A live contract on the Rinkeby test chain can be found at
0xfe054487316ad98abefa3d3ee7852534c5bf413a.  https://rinkeby.etherscan.io/address/0xfe054487316ad98abefa3d3ee7852534c5bf413a

## Using a PCG contract

All of the compiled Tracery generators share a parent contract, pcg_owner.
Its ABI (in string form) is:

```"[{\"constant\":false,\"inputs\":[],\"name\":\"kill\",\"outputs\":[],\"payable\":false,\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"getMyContent\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"maxIter\",\"type\":\"uint256\"}],\"name\":\"createContent\",\"outputs\":[{\"name\":\"\",\"type\":\"bool\"}],\"payable\":false,\"type\":\"function\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"name\":\"name\",\"type\":\"string\"},{\"indexed\":false,\"name\":\"creator\",\"type\":\"address\"}],\"name\":\"ContentCreated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"name\":\"creator\",\"type\":\"address\"}],\"name\":\"ContentAlreadyCreated\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"name\":\"creator\",\"type\":\"address\"}],\"name\":\"IterationsExpired\",\"type\":\"event\"}]"```

Or, in JSON form:

```javascript
[{
    constant: false,
    inputs: [],
    name: "kill",
    outputs: [],
    payable: false,
    type: "function"
}, {
    constant: true,
    inputs: [],
    name: "getMyContent",
    outputs: [{
        name: "",
        type: "string"
    }],
    payable: false,
    type: "function"
}, {
    constant: false,
    inputs: [{
        name: "maxIter",
        type: "uint256"
    }],
    name: "createContent",
    outputs: [{
        name: "",
        type: "bool"
    }],
    payable: false,
    type: "function"
}, {
    anonymous: false,
    inputs: [{
        indexed: false,
        name: "name",
        type: "string"
    }, {
        indexed: false,
        name: "creator",
        type: "address"
    }],
    name: "ContentCreated",
    type: "event"
}, {
    anonymous: false,
    inputs: [{
        indexed: false,
        name: "creator",
        type: "address"
    }],
    name: "ContentAlreadyCreated",
    type: "event"
}, {
    anonymous: false,
    inputs: [{
        indexed: false,
        name: "creator",
        type: "address"
    }],
    name: "IterationsExpired",
    type: "event"
}]
```

In the Geth shell, you can use the following code to access the smart
contract and generate your very own, unique, procedurally generated content:

```javascript
// Instantiate the contract ABI.
var cAbi = JSON.parse( "contract string here" );
var contract = eth.contract( cAbi ).at( "address string here" )

// Specify an account to pay for string creation
eth.defaultAccount = eth.accounts[0]
personal.unlockAccount( eth.defaultAccount, "yourpassword" )

// Create the string, which is stored on the blockchain.
// Returns a transaction ID, wait for it to complete.
contract.createContent( 1, {gas:200000} )

// Retrieve the string corresponding to the sending account (a constant
// operation, no transaction created.
contract.getMyContent()
```

Your string is guaranteed to be unique (up to hash collisions) within this
particular contract.  You can only create the string once; there is no
way to clear it.  Perhaps this will be a paid option later.  :)

Note that this is a very expensive operation in gas.  The default gas will
not be enough for the transaction to succeed.  The 'animal' contract typically
uses around 115000 gas.

Example output from the 'animal' tracery generator:
```
"The purple zebra of the forest is called Darcy"
```

## Creating a PCG contract.

### Dependencies

geth: Ethereum node and Javascript shell

solc: Solidity compiler
  
scons: Build tool (apt-get install scons)
  * apt-get install scons

python

'ply' module: pure Python parser module
   * Use "pip install ply" for now

### Build process

Running 'scons' will build the default target, currently 'animal.tracery'.
All output will go into the 'build' directlry.

A javascript file will be created that has the compiled contract in JSON
form, and some utility functions for adding it or using it.

From the geth console:

```javascript
loadScript( "build/animal.js" )
```
You can then use the helper functions to either create your own version
of the contract, or access the existing one.  Example usage:

```javascript
// Use the ABI to access an existing contract
c = getContract( "0xfe054487316ad98abefa3d3ee7852534c5bf413a" )

// Create a new contract
// Must have set eth.defaultAccount first and unlocked the account
// (This is super-expensive.)
c = createContract()

// Show events from contract:
showEvents( c )
```

### Building your own tracery file with the complier

If you just want to try out the compiler, it can be run from the base
directory as:

```
python -m tracery2eth.main <tracery input> <solidity output>
```

The ```--contract <contract name>``` option lets you specify a contract name,
and the ```--rule <origin rule>``` lets you pick which rule from the Tracery
definition to expand.  ```--verbose``` prints out status of parsing and
generating the Solidity code.

### Building your own tracery file with the build system.

Put your tracery file in src.

Edit ```src/Sonscript``` to change or add your file:

```python
Default( env.TraceryContract( 'myFile.tracery',
                              contract = 'myContract' ) )
```

After running scons, the resulting .js and .json files will be in
the build directory.

### Limitations

Ethereum doesn't support contracts larger than 24000 bytes.  See
https://github.com/ethereum/EIPs/issues/170  It is easy to create a tracery
file that is too large to be compiled into a working contract, and no
warning is given.

Tracery modifiers are not currently supported.

Compilation does not fail on syntax errors.

I'm unsure whether it's possible, in Tracery, to use # or [ or ] in a literal.
My current parser does not support this.

## Example credits

src/animals.tracery and src/pets.tracery are taken from Kate Compton's tracery
tutorial and github page.

src/bot_teleport.tracery is a slightly edited version of http://cheapbotsdonequick.com/source/bot_teleport

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

