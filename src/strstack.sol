/* -*- mode:javascript -*- */

pragma solidity ^0.4.0;

library strstack {
    struct stack {
	string[8] _elements;
	uint _numUsed;
    }

    function emptyStack() internal returns (stack) {
	return stack( { _elements : [ "", "", "", "", "", "", "", "" ],
			_numUsed : 0 } );
    }
    
    function current( stack self ) internal returns (string) {
	if ( self._numUsed == 0 ) {
	    return "";
	} else {
	    return self._elements[self._numUsed - 1];
	}
    }

    function push( stack self, string newVal ) internal {
	// Check for overflow
	assert( self._numUsed < self._elements.length );
	
	self._elements[ self._numUsed ] = newVal;
	self._numUsed += 1;
    }

    function pop( stack self ) internal {
	if ( self._numUsed > 0 ) {
	    // Should we erase the old element?
	    // I think that just costs us cycles, but no memory is freed anyway.
	    self._numUsed -= 1;
	}
    }

    function nonempty( stack self ) internal returns (bool) {
	return ( self._numUsed > 0 );
    }
}
