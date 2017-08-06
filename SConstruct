# -*- Mode: python -*-

env = Environment()

env['SOLCSRC'] = Dir( 'src' )
solcBuilder = Builder( action = "solc --optimize --combined-json abi,bin,interface src=$SOLCSRC $SOURCE > $TARGET",
                       suffix = ".json",
                       src_suffix = ".sol" )

env.Append( BUILDERS={ 'EthJson' : solcBuilder } )

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
                fileOut.write( "var contractName='" + contractName + "';\n" )
                # Some contracts are built from src, others from build,
                # I can't figure out how to control the JSON output.
                fileOut.write( "if ( ('src/' + contractName) in compilerOutput.contracts ) { contractName = 'src/' + contractName; }\n" )
                fileOut.write( "if ( ('build/' + contractName) in compilerOutput.contracts ) { contractName = 'build/' + contractName; }\n" )
                fileOut.write( "// Template from " + str(templateFile) + "\n" )
                fileOut.write( templateIn.read() )

jsonWrapper = Builder(
    action = wrapJson,
    suffix = ".js",
    src_suffix = ".json",
    source_scanner = Scanner( function = js_template_scanner )
)

env.Append( BUILDERS={ 'EthJs' : jsonWrapper } )

# I can't figure out how to tell SCONS to automatically build the
# needed .json file.
def EthContract( self, solcFile, contract ):
    json = self.EthJson( solcFile )
    contractName = str(solcFile) + ":" + contract
    js = self.EthJs( json, CONTRACT=contractName )
    return js

env.AddMethod( EthContract, "EthContract" )

traceryCompiler = Builder( action = "python -m tracery2eth.main $CONTRACTOPT $ORIGINOPT $SOURCE $TARGET",
                       suffix = ".sol",
                       src_suffix = ".tracery" )

env.Append( BUILDERS={ 'SolidityFromTracery' : traceryCompiler } )

def TraceryContract( self, traceryFile,
                     contract = "tracery",
                     origin = "origin" ):
    if contract != "tracery":
        env['CONTRACTOPT'] = '--contract ' + contract
    if origin != "origin":
        env['ORIGINOPT'] = '--rule ' + origin

    solcFile = env.SolidityFromTracery( traceryFile )
    # FIXME: EthContract expects a string, not a File
    # I don't know how to make it take either.
    js = self.EthContract( solcFile[0], contract )
    return js

env.AddMethod( TraceryContract, "TraceryContract" )

# Put artifacts in build subdirectory.
env.SConscript( "src/SConscript",
                exports = ['env'],
                variant_dir="build", duplicate=0 )

