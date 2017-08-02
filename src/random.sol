/* -*- mode:javascript -*- */

pragma solidity ^0.4.0;

library poorRNG {
    struct random {
	uint _seed;
    }

    function newRandom() internal returns (random) {
	var bHash = block.blockhash( block.number - 1 );
	var seed = uint( keccak256( msg.sender, bHash ) );
	return random( { _seed : seed } );
    }
    
    function nextInt32( random self ) internal returns (uint32) {
	// These values come from Knuth's MMX.  They are not guaranteed to
	// produce a full cycle for the 256-bit seed, but I can't find any
	// source for the factorization of 2^256-1.
	var m = uint( 6364136223846793005 );
	var c = uint( 1442695040888963407 );
	self._seed = ( m * self._seed ) + c;
	return uint32( self._seed >> 32 );
    }
}

