module Elm.ProgramInterface exposing (ElmDocs, ProgramInterface, extract)

{-| Parse an Elm module, attempt to locate a `main` function with a `Program`
type, and collect the parts of the AST relevant to the TypeScript declaration
file for the program.
-}

import Elm.AST exposing (SignatureAST, TypeAnnotationAST(..), toSignatureAST)
import Elm.Parser as Parser
import Elm.Processing as Processing
import Elm.RawFile as RawFile
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation
import Elm.Syntax.Expression exposing (Function, FunctionImplementation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Error exposing (Error)
import Parser exposing (deadEndsToString)
import Util.List


type alias ElmDocs =
    String


type alias ProgramInterface =
    { moduleParents : List String
    , moduleName : String
    , docs : Maybe ElmDocs
    , flags : TypeAnnotationAST
    , ports : List SignatureAST
    }


extract : File -> Result Error ProgramInterface
extract file =
    let
        mainFunction =
            getMainFunction file
    in
    Result.map4
        (\( moduleParents, moduleName ) docs flags ports ->
            { moduleParents = moduleParents
            , moduleName = moduleName
            , docs = docs
            , flags = flags
            , ports = ports
            }
        )
        (getNestedModuleName file)
        (Result.map getDocumentation mainFunction)
        (Result.andThen getFlags mainFunction)
        (Ok (getPorts file))


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


getDocumentation : Function -> Maybe ElmDocs
getDocumentation { documentation } =
    Maybe.map Node.value documentation


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


getPorts : File -> List SignatureAST
getPorts file =
    let
        isPortModule =
            file.moduleDefinition |> Node.value |> Module.isPortModule
    in
    if isPortModule then
        Util.List.filterMap getPortFromNode file.declarations

    else
        []


getPortFromNode : Node Declaration -> Maybe SignatureAST
getPortFromNode declarationNode =
    case Node.value declarationNode of
        PortDeclaration signature ->
            Just (toSignatureAST signature)

        _ ->
            Nothing
