#!/usr/bin/python

import argparse
import json
from tracery import parseGrammar
from solidity import emitContract

def compile( traceryFile,
             solidityFile,
             contract = "tracery",
             rule = "origin",
             verbose = False ):
    with open( traceryFile, "r" ) as inFile:
        grammar = json.load( inFile )

    rules = parseGrammar( grammar, verbose )
    with open( solidityFile, "w" ) as outFile:
        emitContract( rules,
                      outFile,
                      contract = contract,
                      origin = rule,
                      verbose = verbose )
            
def main():
    parser = argparse.ArgumentParser( description="Compile a tracery grammar to a Solidity contract." )
    parser.add_argument( 'tracery',
                         help='Tracery (JSON) input file' )
    parser.add_argument( 'solidity',
                         help='Soldity output file' )
    parser.add_argument( '-v', '--verbose',
                         action = "store_const",
                         const = True,
                         default = False,
                         help = 'Dump lots of debugging output.' )
    parser.add_argument( '-c', '--contract',
                         action = "store",
                         default = "tracery",
                         help = 'Contract name to use.' )
    parser.add_argument( '-r', '--rule',
                         action = "store",
                         default = "origin",
                         help = 'Starting tracery rule to expand.' )
    args = parser.parse_args()
    compile( traceryFile = args.tracery,
             solidityFile = args.solidity,
             contract = args.contract,
             rule = args.rule,
             verbose = args.verbose )

if __name__ == "__main__":
    main()
