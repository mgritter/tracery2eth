"""
Functions for emitting contract code.
"""

class PackedLiterals:
    def __init__( self ):
        self.packed = ""

    def addLiteral( self, text ):
        if text not in self.packed:
            self.packed += text

    def literalIndex( self, text ):
        return self.packed.find( text )

# FIXME: do a real version
def escapeLiteral( x ):
    return x.replace( "\n", "\\n" )
        
class ContractWriter:
    def __init__( self,
                  outFile,
                  contractName,
                  ruleset,
                  verbose = False ):
        self.outFile = outFile
        self.contractName = contractName
        self.verbose = verbose
        self.ruleset = ruleset
        self.packed = PackedLiterals()
        
        self.ruleCounter = {}

    def write( self, indent, text ):
        for line in text.split( "\n" ):
            self.outFile.write( " " * indent )
            self.outFile.write( line )
            self.outFile.write( "\n" )
        
    def preamble( self ):
        self.write( 0, """
pragma solidity ^0.4.0;

import "src/strbuf.sol";
import "src/strstack.sol";
import "src/random.sol";
import "src/pgcowner.sol";
""")

    def contractStart( self ):
        self.write( 0, """
contract {} is pgc_owner {{
""".format( self.contractName ) )

    def usingDeclarations( self ):
        self.write( 4, """
using poorRNG for poorRNG.random;
using strbuf for strbuf.strbuf;
using strstack for strstack.stack;
""")

    def traceryState( self ):
        # We need one stack for every dynamically-generated rule
        # In the absence of tests for maximum stack depth, I just
        # gave a maximum depth of 8 to everybody.
        self.write( 4, """
struct TraceryState {
    string _literals;
    poorRNG.random _rng;
    strbuf.strbuf _buf;
""")
        for rule in self.ruleset.generatedRules:
            self.write( 8, "strstack.stack _{};".format( rule ) )
        self.write( 4, "}" )

    def rule2Function( self, rule ):
        return "expand_" + rule

    def dynRule2Function( self, rule ):
        n = self.ruleCounter.get( rule, 0 ) + 1
        self.ruleCounter[rule] = n
        return "expand_" + rule + "_" + str( n )

    def functionDecl( self, fn ):
        self.write( 4,
                    "\nfunction {fn}( TraceryState self ) internal {{"
                    .format( fn = fn ) )
    
    def expandGenerated( self, r ):
        fn = self.rule2Function( r )
        self.functionDecl( fn )
        self.write( 4, """
    self._buf.append( self.{stack}.current() );
}}
""".format( stack = "_" + r ) )

    # callback for normal rule expansion
    def endFunction( self, fn, ast ):
        self.write( 4, "}} // end function {}".format( fn ) )
    
    def expandBoth( self, r, ast ):
        fn = self.rule2Function( r )
        self.functionDecl( fn )
        self.write( 8, """
if ( self.{stack}.nonempty() ) {{
    self._buf.append( self.{stack}.current() );
    return;
}}
        """.format( stack = "_" + r ) )
        self.expandStatic_body( r, ast, self.endFunction )

    def expandStatic( self, r, ast ):
        fn = self.rule2Function( r )
        self.functionDecl( fn )
        self.expandStatic_body( r, ast, self.endFunction )

    def ifelse( self, i, numChoices ):
        if i == 0:
            self.write( 8, 'if ( n == {} ) {{'.format( i ) )
        elif i < numChoices - 1:
            self.write( 8, '}} else if ( n == {} ) {{'.format( i ) )
        else:
            self.write( 8, '} else {' )

    def astToCode( self, a, dynRulesMap, packed ):
        if a.isLiteral:
            self.write( 12,
                        'self._buf.appendPacked( self._literals, {}, {} ); // "{}" '
                        .format( packed.literalIndex( a.value ),
                                 len( a.value ),
                                 escapeLiteral( a.value ) ) )
        elif a.isGenerator:
            if a.pop:
                self.write( 12,
                            'self.{stack}.pop();'
                            .format( stack = "_" + a.name ) )
            else:
                fn = self.dynRule2Function( a.name )
                dynRulesMap[fn] = a
                self.write( 12,
                            '{}( self );'
                            .format( fn ) )
        else:
            # A rule call
            self.write( 12,
                        '{}( self );'
                        .format( self.rule2Function( a.name ) ) )
            
    def expandStatic_body( self, r, astChoices,
                           endFunction ):
        dynRulesMap = {}
        
        # find all the literals and pack them
        
        packed = self.packed
        for ast in astChoices:
            for a in ast:
                if a.isLiteral:
                    packed.addLiteral( a.value )

        numChoices = len( astChoices )
        if ( numChoices > 1 ):
            self.write( 8,
                        'var n = self._rng.nextInt32() % {};'
                        .format( numChoices ) )
        else:
            # FIXME: refactor to make this more efficient? Or just let the
            # compiler try to optimize it?
            self.write( 8, 'int n = 0;' )

        if self.verbose:
            print numChoices, "choices for", r
            
        for i in range( numChoices ):
            self.ifelse( i, numChoices )
            
            if len( astChoices[i] ) == 0:
                # FIXME: just return "" from a generator that does this?
                print "Zero-length choice detected."
            
            for a in astChoices[i]:
                if self.verbose:
                    print r, i, a

                self.astToCode( a, dynRulesMap, packed ) 

        # End of if/else block
        self.write( 8, '}' );
        # End function callback
        endFunction( r, astChoices )
    
        # Now generate any dynamic rules that were generated..
        # (We're not doing any deduplication here.)
        for ( fn, ast ) in dynRulesMap.iteritems():
            self.generateRule( fn, ast )

    def generateRule( self, functionName, ast ):
        if self.verbose:
            print "Writing rule", functionName, "for", ast.name

        self.functionDecl( functionName )

        # Create a new buffer and put it in the state
        self.write( 8, 'var tmp = self._buf.replaceWithNew( 40 );' )

        # Nested function for the callback
        # So it can access 'self' and 'ast'.
        def generatePostfix( ignore, ignore2 ):
            # Store the calculated value and restore the original buffer
            # ast here is *our* AST.
            self.write( 8,
                          'self.{stack}.push( self._buf.finalize() );'
                          .format( stack = '_' + ast.name ) );
            self.write( 8, 'self._buf.replaceWithOld( tmp );' )
            self.write( 4, '}' );
        
        # All generated rules have a single choice:
        self.expandStatic_body( ast.name, [ ast.content ],
                                generatePostfix )
    
    def ruleFunctions( self ):
        rset = self.ruleset
        allRules = rset.allRules()
        try:
            while True:
                r = allRules.pop()
                if r in rset.generatedRules:
                    if r in rset.rules:
                        if self.verbose:
                            print "Writing rule", r, "as dynamic and static"
                        self.expandBoth( r, rset.rules[r] )
                    else:
                        if self.verbose:
                            print "Writing rule", r, "as dynamic"
                        self.expandGenerated(  r )
                else:
                    if self.verbose:
                        print "Writing rule", r, "as static"
                    self.expandStatic( r, rset.rules[r] )
                
        except KeyError:
            pass

    def mainFunction( self, origin  ):
        stacks = [ ", _{} : strstack.emptyStack()\n".format( r )
                   for r in self.ruleset.generatedRules ]
    
        self.write( 4, """
function _createContent( poorRNG.random rng ) internal returns (string) {{
    var t = TraceryState( {{ _literals : "{literals}", 
                            _rng : rng,
                            _buf : strbuf.newBuffer( 140 )
                            {stacks} }} );
    {fn}( t );
    return t._buf.finalize();
}}
""".format( fn=self.rule2Function( origin ),
            stacks = "".join( stacks ),
            literals = escapeLiteral( self.packed.packed ) ) )

    def contractEnd( self ):
        self.write( 0, "}" )
                       
def emitContract( rules,
                  outFile,
                  contract = "tracery",
                  origin = "origin",
                  verbose = False ):
    if origin not in rules.rules:
        raise KeyError, "Origin rule '" + origin + "' not in Tracery grammar."
    
    w = ContractWriter( outFile,
                        contractName = contract,
                        ruleset = rules,
                        verbose = verbose )
    w.preamble()
    w.contractStart()
    w.usingDeclarations()
    w.traceryState()
    w.ruleFunctions()
    w.mainFunction( origin )
    w.contractEnd()
    
