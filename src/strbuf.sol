/* -*- mode:javascript -*- */

pragma solidity ^0.4.0;

library strbuf {
    struct strbuf {
	/* Packed array of characters */
	/* This gives a warning, see 
	   https://github.com/ethereum/solidity/pull/2551
	   for a compiler fix */
	bytes _buf;

	/* Actual length used */
	uint _len;
    }

    function newBuffer( uint sizeEstimate ) internal returns (strbuf) {
	return strbuf( { _buf: new bytes( sizeEstimate ),
			 _len: 0 } );
    }

    function replaceWithNew( strbuf self,
			     uint sizeEstimate ) internal returns ( strbuf ret ) {
	ret = strbuf( { _buf: self._buf,
	                _len: self._len } );
         self._buf = new bytes( sizeEstimate );
        self._len = 0;
    }

    function replaceWithOld( strbuf self, strbuf old ) internal {
	self._buf = old._buf;
	self._len = old._len;
    }

    /* This version copies only 32-byte words and assumes it can stomp
       on the last 32-byte word.  But they need not be aligned!
       This means you should allocate an extra word at the end, if
       unaligned dest is possible.
     */
    function memcpy32( uint dest, uint src, uint count ) internal {
	/* TODO: loop unrolling? */
	for( ; count >= 32; count -= 32 ) {
	    assembly {
		mstore( dest, mload( src ) )
	    }
	    dest += 32;
	    src += 32;
	}
	if ( count > 0 ) {
	    assembly {
		mstore( dest, mload( src ) )
	    }
	}
    }
    
    function copyToString( string dest, bytes array, uint count ) internal {
        uint dstStart;
	uint srcStart;
	/* Not sure where the in-memory layout of a string or bytes
	   is documented? Both appear to start immediately after a length.
	   (There's an offhand comment in the solidity docs.) */	
        assembly {
	    dstStart := add(dest, 0x20)
	    srcStart := add(array, 0x20)
	}
	memcpy32( dstStart, srcStart, count );	
    }

    function copyToBytes( bytes dest, uint offset,
			  bytes array, uint count ) internal {
        uint dstStart;
	uint srcStart;
        assembly {
	    dstStart := add(dest, 0x20)
	    srcStart := add(array, 0x20)
	}
	memcpy32( dstStart + offset, srcStart, count );	
    }

    function finalize( strbuf self ) internal returns (string) {
	/* Maybe we should just take the chars instead? */
	var ret = new string( self._len );
	copyToString( ret, self._buf, self._len );
	return ret;
    }

    function resizeIfNecessary( strbuf self, uint newLen ) internal {
	/* Ensure enough room to write a full word at the end */
	if ( self._buf.length < newLen + 31 ) {
	    // FIXME: round up to next 32-byte value?
	    var newSize = ( newLen + 31 ) * 2;
	    bytes memory newBuf = new bytes( newSize );
	    copyToBytes( newBuf, 0, self._buf, self._len );
	    self._buf = newBuf;
	}
    }
    
    function append( strbuf self, string atEnd ) internal {
	// FIXME: make sure string->bytes conversion not a deep copy
	var a = bytes( atEnd );
	var newLen = self._len + a.length;
	resizeIfNecessary( self, newLen );
	copyToBytes( self._buf, self._len, a, a.length );
	self._len = newLen;
    }

    function appendPacked( strbuf self, string atEnd,
    	      		   uint offset, uint len ) internal {
	var src = bytes( atEnd );
	var newLen = self._len + len;
	resizeIfNecessary( self, newLen );
	bytes memory dst = self._buf;
	
	uint dstStart;
	uint srcStart;
        assembly {
	    dstStart := add(dst, 0x20)
	    srcStart := add(src, 0x20)
	}
	memcpy32( dstStart + self._len, srcStart + offset, len );
	self._len = newLen;
    }
}
