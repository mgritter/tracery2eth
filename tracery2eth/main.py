#!/usr/bin/python

import argparse
import json
from tracery import parseGrammar
from solidity import emitContract

def compile( traceryFile, solidityFile ):
    with open( traceryFile, "r" ) as inFile:
        grammar = json.load( inFile )

    rules = parseGrammar( grammar )
    with open( solidityFile, "w" ) as outFile:
        emitContract( rules, outFile )
            
def main():
    parser = argparse.ArgumentParser( description="Compile a tracery grammar to a Solidity contract." )
    parser.add_argument( 'tracery',
                         help='Tracery (JSON) input file' )
    parser.add_argument( 'solidity',
                         help='Soldity output file' )
    args = parser.parse_args()
    compile( args.tracery,
             args.solidity )
           
                         
if __name__ == "__main__":
    main()
