/* -*- mode:javascript -*- */

pragma solidity ^0.4.0;

import "src/mortal.sol";
import "src/random.sol";

contract pgc_owner is mortal {
    using poorRNG for poorRNG.random;
    
    /* Content storage, one per user */
    mapping( address => string ) internal _owners;
    
    /* Content hashes, to check uniqueness */
    mapping( bytes32 => uint ) internal _generated;

    /// Sent whenever a new string is created and stored
    event ContentCreated( string name, address creator );

    /// Sent when a sender already has a piece of content assigned.
    event ContentAlreadyCreated( address creator );

    /// Sent if we failed to generate unique content.
    event IterationsExpired( address creator );

    /// Abstract method to create content
    function _createContent( poorRNG.random rng ) internal returns (string);

    /// Create a string using a procedural mechanism implemented
    /// by _createContent.  This string is saved with the sender
    /// id for later retrieval, and is checked against other created
    /// strings for uniqueness.
    ///
    /// If the created string is non-unique, we will retry up to
    /// maxIter times.
    function createContent( uint maxIter ) external returns (bool) {
	string storage ownedContent = _owners[msg.sender];
	if ( bytes( ownedContent ).length > 0 ) {
	    /* He's already got one. */
	    ContentAlreadyCreated( msg.sender );
	    return false;
	}
	var rng = poorRNG.newRandom();
	for ( uint iters = 0; iters < maxIter; ++iters ) {
	    var content = _createContent( rng );
	    bytes32 contentHash = keccak256( content );
	    if ( _generated[contentHash] == 0 ) {
		_generated[contentHash] = 1;
		_owners[msg.sender] = content;
		ContentCreated( content, msg.sender );
		return true;
	    }
	}
	IterationsExpired( msg.sender );
	return false;
    }
    
    /// Retrieve the string stored for the sender by createContent()
    function getMyContent() external constant returns (string) {
	return _owners[ msg.sender ];
    }
}
