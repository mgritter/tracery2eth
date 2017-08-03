"""
Functions for parsing Tracery into a set of rules and actions.
"""

import ply.lex as lex
import ply.yacc as yacc

# AST types
class Literal:
    def __init__( self, text ):
        self.value = text
        self.isLiteral = True
        self.isGenerator = False

    def __repr__( self ):
        return 'Literal("{}")'.format( self.value )
    
class RuleGenerator:
    def __init__( self, name, content, pop = False ):
        self.name = name
        self.content = content   # Recursively, a list of AST elements
        self.pop = pop
        self.isLiteral = False
        self.isGenerator = True

    def __repr__( self ):
        if self.pop:
            return 'RulePop({})'.format( self.name )
        else:
            return 'RuleGenerator({},{})'.format( self.name, str( self.content ) )

class RuleApplication:
    def __init__( self, name ):
        self.name = name
        # Not yet supported
        self.modifiers = []
        self.isLiteral = False
        self.isGenerator = False

    def __repr__( self ):
        return 'RuleApplication({})'.format( self.name )
        
class RuleSet:
    def __init__( self ):
        # Map of top-level rule names to list of lists of AST options
        self.rules = {}
        
        # Complete list of rules named anywhere in the grammar
        self.allRules = set()

    def addOption( self, rule, ast ):
        if rule in self.rules:
            self.rules[rule].append( ast )
        else:
            self.rules[rule] = [ast]

    def visitRuleName( self, rule ):
        self.allRules.add( rule )
        
class ParserError(Exception):
    pass

class TraceryLexer:
    def __init__( self ):
        pass
    
    tokens = (
        'LBRACKET',
        'RBRACKET',
        'HASH',
        'COLON',
        'PERIOD',
        'LITERAL'
    )

    t_LBRACKET = r'\['
    t_RBRACKET = r'\]'
    t_HASH = r'[#]'    # PLY uses a re mode that allows comments!
    t_COLON = r':'
    t_PERIOD = r'\.'
    t_LITERAL = r'[^\[\]#:.]+'

    def t_error( self, t ):
        print "Somehow we got a lexer error despite matching everything"
        print "on string: '{}'".format( t.value )
        raise ParserError, "Failed to lex."

    def build( self, **kwargs ):
        self.lexer = lex.lex( module = self, **kwargs )
        return self.lexer
        
def p_emptyrule( p ):
    '''rule :'''
    p[0] = []

def p_rule( p ):
    '''rule : literal rule
            | apply rule
            | generate rule'''
    p[0] = [ p[1] ] + p[2]

def p_literal( p ):
    '''literal : LITERAL'''
    p[0] = Literal( text = p[1] )

def p_apply_unmodified( p ):
    '''apply : HASH LITERAL HASH'''
    p[0] = RuleApplication( name = p[2] )

def p_apply_modified( p ):
    '''apply : HASH LITERAL PERIOD modifiers HASH'''
    print "Warning: modifiers not supported."
    p[0] = RuleApplication( name = p[2] )

def p_modifier( p ):
    '''modifiers : LITERAL'''
    p[0] = [p[1]]

def p_multiple_modifier( p ):
    '''modifiers : LITERAL PERIOD modifiers'''
    p[0] = [p[1]] + p[2]
    

def isPop( ast ):
    return len( ast ) == 1 and \
        ast[0].isLiteral and \
        ast[0].value == "POP"

def p_generate( p ):
    '''generate : LBRACKET LITERAL COLON rule RBRACKET'''
    p[0] = RuleGenerator( name = p[2],
                          content = p[4],
                          pop = isPop( p[4] ) )

def p_error( p ):
    if p == None:
        print "Syntax error at EOF." 
    else:
        print "Syntax error at token '{}'.".format(p)
        
lexer = TraceryLexer().build()
tokens = TraceryLexer.tokens
parser = yacc.yacc()

import pprint

def visitRuleNames( rset, astList ):
    for a in astList:
        if a.isGenerator:
            rset.visitRuleName( a.name )
            if not a.pop:
                visitRuleNames( rset, a.content )
    
def parseGrammar( grammar ):
    # The input grammar is a dictionary of rules.
    # Unfortunately this list may be incomplete because rules may create
    # other rules that were previously undefined.
    output = RuleSet()

    for ruleName in grammar.iterkeys():
        output.visitRuleName( ruleName )
        for option in grammar[ruleName]:            
            ast = parser.parse( option, lexer=lexer )
            output.addOption( ruleName, ast )
            visitRuleNames( output, ast )

    for ( ruleName, options ) in output.rules.iteritems():
        print "rule:", ruleName
        for o in options:
            print "  option:", o

    print "all rule names found: ",
    print " ".join( list( output.allRules ) )
            
    
