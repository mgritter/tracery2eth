/* -*- mode:javascript -*- */

pragma solidity ^0.4.0;

import "src/strbuf.sol";
import "src/mortal.sol";

contract test is mortal {
    using strbuf for strbuf.strbuf;

    string public lastResult;
    
    function doit1( uint n ) constant  {
	strbuf.strbuf memory buf = strbuf.newBuffer( 80 );
	nestedIf( buf, n );
	lastResult = buf.finalize();
    }

    /*
    function doit2( uint n ) constant  {
	strbuf.strbuf memory buf = strbuf.newBuffer( 80 );
	staticArray( buf, n );
	lastResult = buf.finalize();
    }

    function doit3( uint n ) constant  {
	strbuf.strbuf memory buf = strbuf.newBuffer( 80 );
	packedLiteral( buf, n );
	lastResult = buf.finalize();
    }
    */

    function nestedIf( strbuf.strbuf buf, uint n ) constant internal returns (string) {
	if ( n == 0 ) {
	    buf.append( "unicorn" );
	} else if ( n == 1 ) {
	    buf.append( "raven" );
	} else if ( n == 2 ) {
	    buf.append( "sparrow" );
	} else if ( n == 3 ) {
	    buf.append( "scorpion" );
	} else if ( n == 4 ) {
	    buf.append( "coyote" );
	} else if ( n == 5 ) {
	    buf.append( "eagle" );
	} else if ( n == 6 ) {
	    buf.append( "owl" );
	} else if ( n == 7 ) {
	    buf.append( "lizard" );
	} else if ( n == 8 ) {
	    buf.append( "zebra" );
	} else if ( n == 9 ) {
	    buf.append( "duck" );
	} else {
	    buf.append( "kitten" );
	}
    }

    function staticArray( strbuf.strbuf buf, uint n ) constant internal returns (string) {
	string[11] memory animals = [ "unicorn", "raven", "sparrow", "scorpion",
				      "coyote", "eagle", "owl", "lizard",
				      "zebra", "duck", "kitten" ];
	buf.append( animals[n] );
    }

    function packedLiteral( strbuf.strbuf buf, uint n ) constant internal returns (string ) {
	string memory animals = "unicornravensparrowscorpioncoyoteeagleowllizardzebraduckkitten";
	if ( n == 0 ) {
	    buf.appendPacked( animals, 0, 6);
	} else if ( n == 1 ) {
	    buf.appendPacked( animals, 6, 5 );
	} else if ( n == 2 ) {
	    buf.appendPacked( animals, 11, 7 );
	} else if ( n == 3 ) {
	    buf.appendPacked( animals, 18, 8 );
	} else if ( n == 4 ) {
	    buf.appendPacked( animals, 26, 6 );
	} else if ( n == 5 ) {
	    buf.appendPacked( animals, 32, 5  );
	} else if ( n == 6 ) {
	    buf.appendPacked( animals, 37, 3 );
	} else if ( n == 7 ) {
	    buf.appendPacked( animals, 40, 6 );
	} else if ( n == 8 ) {
	    buf.appendPacked( animals, 46, 5  );
	} else if ( n == 9 ) {
	    buf.appendPacked( animals, 51, 4 );
	} else {
	    buf.appendPacked( animals, 55, 6 );
	}    
    }
}

