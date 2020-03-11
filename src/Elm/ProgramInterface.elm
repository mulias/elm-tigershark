module Elm.ProgramInterface exposing (ProgramInterface, addImportedPorts, extract)

{-| Parse an Elm module, attempt to locate a `main` function with a `Program`
type, and collect the parts of the AST relevant to the TypeScript declaration
file for the program.
-}

import Elm.AST exposing (ExposingAST(..), SignatureAST, TypeAnnotationAST(..), toExposingAST, toSignatureAST)
import Elm.ElmDoc as ElmDoc exposing (ElmDoc)
import Elm.Parser as Parser
import Elm.PortModule as PortModule exposing (PortModule(..))
import Elm.Processing as Processing
import Elm.Project as Project exposing (FindBy(..), Project)
import Elm.RawFile as RawFile
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation
import Elm.Syntax.Expression exposing (Function, FunctionImplementation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Error exposing (Error)
import Parser exposing (deadEndsToString)
import Util.List


type alias ProgramInterface =
    { file : File
    , moduleParents : List String
    , moduleName : String
    , docs : Maybe ElmDoc
    , flags : TypeAnnotationAST
    , ports : PortModule
    }


extract : File -> Result Error ProgramInterface
extract file =
    let
        mainFunction =
            getMainFunction file
    in
    Result.map3
        (\( moduleParents, moduleName ) docs flags ->
            { file = file
            , moduleParents = moduleParents
            , moduleName = moduleName
            , docs = docs
            , flags = flags
            , ports = getPortsInModule file
            }
        )
        (getNestedModuleName file)
        (Result.map getDocumentation mainFunction)
        (Result.andThen getFlags mainFunction)


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
addImportedPorts : Project -> ProgramInterface -> ProgramInterface
addImportedPorts project programInterface =
    case programInterface.ports of
        ModuleWithPorts ports ->
            List.map (readImportedModule project) programInterface.file.imports
                |> List.filterMap Result.toMaybe
                |> List.map getPortsExposedByModule
                |> List.filterMap PortModule.toMaybe
                |> List.concat
                |> (\importedPorts ->
                        { programInterface
                            | ports = ModuleWithPorts (List.concat [ ports, importedPorts ])
                        }
                   )

        NotPortModule ->
            programInterface


getNestedModuleName : File -> Result Error ( List String, String )
getNestedModuleName { moduleDefinition } =
    case
        moduleDefinition
            |> Node.value
            |> Module.moduleName
            |> List.reverse
    of
        [] ->
            Err Error.MissingModuleName

        [ name ] ->
            Ok ( [], name )

        name :: parents ->
            Ok ( List.reverse parents, name )


getMainFunction : File -> Result Error Function
getMainFunction { declarations } =
    declarations
        |> Util.List.findMap getMainFromNode
        |> Result.fromMaybe Error.MissingMainFunction


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


getDocumentation : Function -> Maybe ElmDoc
getDocumentation { documentation } =
    documentation
        |> Maybe.map Node.value
        |> Maybe.map ElmDoc.fromAST


getFlags : Function -> Result Error TypeAnnotationAST
getFlags { signature } =
    signature
        |> Result.fromMaybe Error.MissingMainSignature
        |> Result.map (Node.value >> toSignatureAST)
        |> Result.andThen
            (\{ typeAnnotation } ->
                case typeAnnotation of
                    TypedAST ( _, "Program" ) (flags :: _) ->
                        Ok flags

                    _ ->
                        Err Error.MainNotAProgram
            )


getPortsInModule : File -> PortModule
getPortsInModule file =
    let
        isPortModule =
            file.moduleDefinition |> Node.value |> Module.isPortModule
    in
    if isPortModule then
        ModuleWithPorts (List.filterMap getPortFromNode file.declarations)

    else
        NotPortModule


getPortsExposedByModule : File -> PortModule
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
    PortModule.map (List.filter isExposedPort) modulePorts


getPortFromNode : Node Declaration -> Maybe SignatureAST
getPortFromNode declarationNode =
    case Node.value declarationNode of
        PortDeclaration signature ->
            Just (toSignatureAST signature)

        _ ->
            Nothing


readImportedModule : Project -> Node Import -> Result Error File
readImportedModule project importNode =
    let
        moduleName =
            importNode |> Node.value |> .moduleName |> Node.value
    in
    Project.readFileWith (ModuleName moduleName) project
