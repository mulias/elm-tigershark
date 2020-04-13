module Elm.ProgramInterface exposing (ProgramInterface, fromFile)

{-| Parse an Elm module, attempt to locate a `main` function with a `Program`
type, and collect the parts of the AST relevant to the TypeScript declaration
file for the program.
-}

import Elm.AST exposing (ExposingAST(..), SignatureAST, TypeAnnotationAST(..), toExposingAST, toSignatureAST)
import Elm.ElmDoc as ElmDoc exposing (ElmDoc)
import Elm.ModulePath as ModulePath exposing (ModulePath)
import Elm.Parser as Parser
import Elm.PortModule as PortModule exposing (Port, PortModule(..))
import Elm.Processing as Processing
import Elm.Project as Project exposing (Project)
import Elm.RawFile as RawFile
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation
import Elm.Syntax.Expression exposing (Function, FunctionImplementation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Main.Error as Error exposing (Error(..))
import Parser exposing (deadEndsToString)
import Result.Extra
import Util.List


type alias ProgramInterface =
    { file : File
    , modulePath : ModulePath
    , docs : Maybe ElmDoc
    , flags : TypeAnnotationAST
    , ports : PortModule
    }


{-| Given a `File`, which is the AST returned by `elm-syntax` representing a
full Elm module, pull out all the information relevant to the main program
function in the module. Fails if:

  - The module does not have a top declaration line with the module's name
  - The module does not contain a `main` function
  - The `main` function does not have a type annotation
  - The type annotation for `main` is something other than a `Program` type

This function assumes that the module file provided is for the main program,
and only extracts the information provided in that module. Additional
processing may be necessary to add information from imported modules.

-}
fromFile : Project -> File -> Result Error ProgramInterface
fromFile project file =
    let
        mainFunction =
            getMainFunction file
    in
    Result.map4
        (\modulePath docs flags ports ->
            { file = file
            , modulePath = modulePath
            , docs = docs
            , flags = flags
            , ports = ports
            }
        )
        (getModulePath file)
        (Result.map getDocumentation mainFunction)
        (Result.andThen getFlags mainFunction)
        (getPorts project file)


{-| Elm modules are described as a path with period separators, for example
`module One.Two.Three exposing ...` declares the module `Three` with parents
`One` and `Two`. Returns the list of parents and current module name, for
example `(["One", "Two"], "Three")`
-}
getModulePath : File -> Result Error ModulePath
getModulePath { moduleDefinition } =
    moduleDefinition
        |> Node.value
        |> Module.moduleName
        |> ModulePath.fromNamespace
        |> Result.fromMaybe (Fatal Error.MissingModuleName)


{-| Try to fund a function in the module with the name "main". The returned
`Function` AST may or may not have a type signature.
-}
getMainFunction : File -> Result Error Function
getMainFunction { declarations } =
    declarations
        |> Util.List.findMap getMainFromNode
        |> Result.fromMaybe (NonFatal Error.MissingMainFunction)


getMainFromNode : Node Declaration -> Maybe Function
getMainFromNode declarationNode =
    case Node.value declarationNode of
        FunctionDeclaration function ->
            if (function.declaration |> Node.value |> .name |> Node.value) == "main" then
                Just function

            else
                Nothing

        _ ->
            Nothing


{-| Returns the documentation for the given function, if there is any.
-}
getDocumentation : Function -> Maybe ElmDoc
getDocumentation { documentation } =
    documentation
        |> Maybe.map Node.value
        |> Maybe.map ElmDoc.fromAST


{-| Get the type AST for the flags of a `Program` type. Fails if the provided
function (assumed to be `main`) is not a `Program`.
-}
getFlags : Function -> Result Error TypeAnnotationAST
getFlags { signature } =
    signature
        |> Result.fromMaybe (Fatal Error.MissingMainSignature)
        |> Result.map (Node.value >> toSignatureAST)
        |> Result.andThen
            (\{ typeAnnotation } ->
                case typeAnnotation of
                    TypedAST ( _, "Program" ) (flags :: _) ->
                        Ok flags

                    _ ->
                        Err (Fatal Error.MainNotAProgram)
            )


getPorts : Project -> File -> Result Error PortModule
getPorts project file =
    let
        moduleDef =
            Node.value file.moduleDefinition

        isPortModule =
            Module.isPortModule moduleDef
    in
    if isPortModule then
        Result.map2
            (\portsInModule importedPorts ->
                ModuleWithPorts
                    (List.concat [ portsInModule, importedPorts ])
            )
            (Ok (getPortsInModule file))
            (getImportedPorts project file)

    else
        Ok NotPortModule


{-| Collect all the port function declarations that are in the given module,
regardless of if the ports are exposed by the module or not. Returns a type
which specifies of the module is not declared as a `port module`, and therefore
can't have ports, or is a port module and has a (passably empty) list of ports.
-}
getPortsInModule : File -> List Port
getPortsInModule file =
    let
        moduleDef =
            Node.value file.moduleDefinition

        moduleName =
            Module.moduleName moduleDef
    in
    file.declarations
        |> List.filterMap getPortDeclarationFromNode
        |> List.map
            (\{ name, typeAnnotation } ->
                { name = name
                , typeAnnotation = typeAnnotation
                , declaredInModule = moduleName
                }
            )


{-| Collect all modules imported by the program's module, and if any of those
imported modules are also port modules, add the ports they expose to the
program interface.

  - In the cases where we fail to find an imported module in the project,
    assume that it's an external library import and ignore that module. Elm
    libraries can't use ports.

  - Elm does not allow re-exporting imports, so only direct imports need to be
    checked, no recursive searching necessary.

  - Add all exposed port declarations found in imported port modules. Since we
    don't examine program code, only type signatures, we can't tell when a port
    is being used, what ports are being used, or if the port is called prefixed
    like `MyModule.myPort`, or unprefixed like `myPort`. The safest option is to
    assume everything is used.

-}
getImportedPorts : Project -> File -> Result Error (List Port)
getImportedPorts project file =
    file.imports
        |> List.map getModulePathFromNode
        |> Result.Extra.combine
        |> Result.map (List.filter (\modulePath -> Project.isProjectFile modulePath project))
        |> Result.andThen (List.map (\modulePath -> Project.readFile modulePath project) >> Result.Extra.combine)
        |> Result.map
            (\files ->
                files
                    |> List.map getPortsExposedByModule
                    |> List.concat
            )


{-| Collects all of the port function declarations that are in the given
module, and also exposed by the module. This is useful for when a main program
module imports ports from other port modules.
-}
getPortsExposedByModule : File -> List Port
getPortsExposedByModule file =
    let
        modulePorts =
            getPortsInModule file

        moduleExposingList =
            file.moduleDefinition |> Node.value |> Module.exposingList |> toExposingAST

        isExposedPort { name } =
            case moduleExposingList of
                All ->
                    True

                Explicit list ->
                    List.member name list
    in
    List.filter isExposedPort modulePorts


getPortDeclarationFromNode : Node Declaration -> Maybe SignatureAST
getPortDeclarationFromNode declarationNode =
    case Node.value declarationNode of
        PortDeclaration signature ->
            Just (toSignatureAST signature)

        _ ->
            Nothing


getModulePathFromNode : Node Import -> Result Error ModulePath
getModulePathFromNode importNode =
    importNode
        |> Node.value
        |> .moduleName
        |> Node.value
        |> ModulePath.fromNamespace
        |> Result.fromMaybe (Fatal Error.EmptyFilePath)
