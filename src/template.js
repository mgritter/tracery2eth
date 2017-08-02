function showTxnResponse( e, contract ) {
    if ( typeof contract.address !== 'undefined') {
         console.log('Contract mined! address: ' + contract.address + ' transactionHash: ' + contract.transactionHash);
    }
}

function createContract() {
    var cAbi = JSON.parse( compilerOutput.contracts[contractName].abi );
    var cBin = "0x" + compilerOutput.contracts[contractName].bin;
    var cx = eth.contract( cAbi );
    return cx.new( { from:eth.accounts[0],
                     data:cBin,
                     gas:4700000 },
                     showTxnResponse );
}

function getContract( at ) {
    var cAbi = JSON.parse( compilerOutput.contracts[contractName].abi );
    return eth.contract( cAbi ).at( at );
}

function showEvents( x ) {
    var firstBlock = 0;
    if ( x.transactionHash != null ) {
      firstBlock = eth.getTransaction( x.transactionHash ).blockNumber;
   }
    x.allEvents( {fromBlock:firstBlock, toBlock:'latest' } ).get(
       function ( error, response ) {
          if ( error == null ) {
             for ( var i = 0; i < response.length; ++i ) {
               console.log( response[i].event, 
                            JSON.stringify( response[i].args ) );
             }
          }
       }
    )
    return;
}
