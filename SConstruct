# -*- Mode: python -*-

env = Environment()

solcBuilder = Builder( action = "solc --optimize --combined-json abi,bin,interface $SOURCE > $TARGET",
                       suffix = ".json",
                       src_suffix = ".sol" )

import re

solidity_import_re = re.compile( r'^import\s+"(.*)"\s*$' )
def solidity_scan_import( node, env, path ):
    # It might be better to use solc --ast instead?
    contents = node.get_contents()
    return solidity_import_re.findall( contents )

env.Append( SCANNERS = Scanner( function = solidity_scan_import,
                                skeys = ['.sol'] ) )


defaultTemplate = File( "src/template.js" )

def js_template_scanner( node, env, path ):
    return [ env.get( 'JSTEMPLATE', defaultTemplate ) ]
    
# Create a JS file suitable for importing into geth shell.
def wrapJson( target, source, env ):
    assert len( target ) == 1
    assert len( source ) == 1
    contractName = env['CONTRACT']
    templateFile = env.get( 'JSTEMPLATE', defaultTemplate )
    print "Using template file", templateFile
    with open( str(source[0]), "r" ) as fileIn:
        with open( str(templateFile), "r" ) as templateIn:
            with open( str(target[0]), "w" ) as fileOut:
                fileOut.write( "var compilerOutput=" )
                fileOut.write( fileIn.read().rstrip() )
                fileOut.write( ";\n" )
                fileOut.write( "var contractName='src/" + contractName + "';\n" )
                fileOut.write( "// Template from " + str(templateFile) )
                fileOut.write( templateIn.read() )

jsonWrapper = Builder(
    action = wrapJson,
    suffix = ".js",
    src_suffix = ".json",
    source_scanner = Scanner( function = js_template_scanner )
)

env.Append( BUILDERS={ 'EthJson' : solcBuilder } )
env.Append( BUILDERS={ 'EthJs' : jsonWrapper } )

# I can't figure out how to tell SCONS to automatically build the
# needed .json file.
def EthContract( self, solcFile, contract ):
    json = self.EthJson( solcFile )
    contractName = solcFile + ":" + contract
    js = self.EthJs( json, CONTRACT=contractName )
    return js

env.AddMethod( EthContract, "EthContract" )
    
# Put artifacts in build subdirectory.
env.SConscript( "src/SConscript",
                exports = ['env'],
                variant_dir="build", duplicate=0 )

