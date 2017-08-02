/* -*- mode:javascript -*- */

pragma solidity ^0.4.0;

/*
OK, here's a tracery grammar and we're gonna implement it by hand as a guide
towards later compilation.
{
	"sentence": ["The #color# #animal# of the #natureNoun# is called #name#"]
,	"color": ["orange","blue","white","black","grey","purple","indigo","turquoise"]
,	"animal": ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"]
,	"natureNoun": ["ocean","mountain","forest","cloud","river","tree","sky","sea","desert"]
,	"name": ["Arjun","Yuuma","Darcy","Mia","Chiaki","Izzi","Azra","Lina"]
}
*/

import "src/strbuf.sol";
import "src/random.sol";
import "src/mortal.sol";

library tracery_animal {
    using poorRNG for poorRNG.random;
    using strbuf for strbuf.strbuf;

    struct TraceryState {
	poorRNG.random _rng;
	strbuf.strbuf _buf;

	// None of these rules save state so we don't need that for now
	// nor a stack of buffers for rule text generation.
    }

    function startTracery( poorRNG.random rng ) internal returns (TraceryState) {
	return TraceryState( { _rng : rng,
			       _buf : strbuf.newBuffer( 80 ) } );
    }

    function popBuf( TraceryState self ) internal returns (string) {
	// TODO: stack
	return self._buf.finalize();
    }
    
    function rule_color( TraceryState self ) internal {
	var n = self._rng.nextInt32() % 8;
	if ( n == 0 ) {
	    self._buf.append( "orange" );
	} else if ( n == 1 ) {
	    self._buf.append( "blue" );
	} else if ( n == 2 ) {
	    self._buf.append( "white" );
	} else if ( n == 3 ) {
	    self._buf.append( "black" );
	} else if ( n == 4 ) {
	    self._buf.append( "gray" );
	} else if ( n == 5 ) {
	    self._buf.append( "purple" );
	} else if ( n == 6 ) {
	    self._buf.append( "indigo" );
	} else {
	    self._buf.append( "turquoise" );
	}
    }

    function rule_animal( TraceryState self ) internal {
	var n = self._rng.nextInt32() % 10;
	if ( n == 0 ) {
	    self._buf.append( "unicorn" );
	} else if ( n == 1 ) {
	    self._buf.append( "raven" );
	} else if ( n == 2 ) {
	    self._buf.append( "sparrow" );
	} else if ( n == 3 ) {
	    self._buf.append( "scorpion" );
	} else if ( n == 4 ) {
	    self._buf.append( "coyote" );
	} else if ( n == 5 ) {
	    self._buf.append( "eagle" );
	} else if ( n == 6 ) {
	    self._buf.append( "owl" );
	} else if ( n == 7 ) {
	    self._buf.append( "lizard" );
	} else if ( n == 8 ) {
	    self._buf.append( "zebra" );
	} else if ( n == 9 ) {
	    self._buf.append( "duck" );
	} else {
	    self._buf.append( "kitten" );
	}
    }
    
    function rule_natureNoun( TraceryState self ) internal {
	var n = self._rng.nextInt32() % 9;
	if ( n == 0 ) {
	    self._buf.append( "ocean" );
	} else if ( n == 1 ) {
	    self._buf.append( "mountain" );
	} else if ( n == 2 ) {
	    self._buf.append( "forest" );
	} else if ( n == 3 ) {
	    self._buf.append( "cloud" );
	} else if ( n == 4 ) {
	    self._buf.append( "river" );
	} else if ( n == 5 ) {
	    self._buf.append( "tree" );
	} else if ( n == 6 ) {
	    self._buf.append( "sky" );
	} else if ( n == 7 ) {
	    self._buf.append( "sea" );
	} else {
	    self._buf.append( "desert" );
	}
    }

    function rule_name( TraceryState self ) internal {
	var n = self._rng.nextInt32() % 8;
	if ( n == 0 ) {
	    self._buf.append( "Arjun" );
	} else if ( n == 1 ) {
	    self._buf.append( "Yuuma" );
	} else if ( n == 2 ) {
	    self._buf.append( "Darcy" );
	} else if ( n == 3 ) {
	    self._buf.append( "Mia" );
	} else if ( n == 4 ) {
	    self._buf.append( "Chiaki" );
	} else if ( n == 5 ) {
	    self._buf.append( "Izzi" );
	} else if ( n == 6 ) {
	    self._buf.append( "Azra" );
	} else {
	    self._buf.append( "Lina" );
	}
    }

    function rule_sentence( TraceryState self ) internal {
	self._buf.append( "The " );
	rule_color( self );
	self._buf.append( " " );
	rule_animal( self );
	self._buf.append( " of the " );
	rule_natureNoun( self );
	self._buf.append( " is called " );
	rule_name( self );
    }

}

contract animal is mortal {
    using poorRNG for poorRNG.random;
    using strbuf for strbuf.strbuf;
    using tracery_animal for tracery_animal.TraceryState;
    
    /* Animal storage, one per user */
    mapping( address => string ) internal _owners;
    /* Animal hashes, to check uniqueness */
    mapping( bytes32 => uint ) internal _animals;
    
    event AnimalCreated( string name, address creator );
    event AnimalAlreadyCreated( address creator );
    event AnimalCreationIterationsExpired( address creator );

    function genAnimal( poorRNG.random rng ) internal returns (string) {
	var t = tracery_animal.startTracery( rng );
	t.rule_sentence();
	return t.popBuf();
    }

    function testAnimal() constant returns (string) {
	var rng = poorRNG.newRandom();
	return genAnimal( rng );
    }

    /* Although this returns bool, current clients don't really support
     * checking the return code, so I created an event for each outcome.
     */
    function createAnimal( uint maxIter ) external returns (bool) {
	string storage ownedAnimal = _owners[msg.sender];
	if ( bytes( ownedAnimal ).length > 0 ) {
	    /* He's already got one. */
	    AnimalAlreadyCreated( msg.sender );
	    return false;
	}
	var rng = poorRNG.newRandom();
	for ( uint iters = 0; iters < maxIter; ++iters ) {
	    var animal = genAnimal( rng );
	    bytes32 animalHash = keccak256( animal );
	    if ( _animals[animalHash] == 0 ) {
		_animals[animalHash] = 1;
		_owners[msg.sender] = animal;
		AnimalCreated( animal, msg.sender );
		return true;
	    }
	}
	AnimalCreationIterationsExpired( msg.sender );
	return false;
    }
    
    /* Return a tweetable portion of the animal. */
    function getMyAnimalTweet() external constant returns (byte[140]) {
	bytes memory a = bytes( _owners[ msg.sender ] );
	byte[140] memory ret;
	for ( uint i = 0; i < 140 && i < a.length; ++i ) {
	    ret[i] = a[i];
	}
	return ret;	
    }

    /* Returns full string. */
    function getMyAnimal() external constant returns (string) {
	return _owners[ msg.sender ];
    }
}

