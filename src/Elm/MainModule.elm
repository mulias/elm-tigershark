module Elm.MainModule exposing (extract)

{-| Parse an Elm module and collect the parts of the AST relevant to the
TypeScript declaration file.
-}

import Elm.AST exposing (SignatureAST, TypeAnnotationAST(..), toSignatureAST)
import Elm.Parser as Parser
import Elm.Processing as Processing
import Elm.RawFile as RawFile
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.Expression exposing (Function, FunctionImplementation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Error exposing (Error)
import List.Nonempty exposing (Nonempty)
import Parser exposing (deadEndsToString)
import Util.List


type alias ModuleName =
    Nonempty String


type alias Ports =
    List SignatureAST


type alias MainModule =
    { moduleName : ModuleName
    , mainDocumentation : Maybe Documentation
    , flags : TypeAnnotationAST
    , ports : Ports
    }


extract : File -> Result Error MainModule
extract file =
    let
        mainFunction =
            getMainFunction file
    in
    Result.map4 MainModule
        (getModuleName file)
        (Result.map getDocumentation mainFunction)
        (Result.andThen getFlags mainFunction)
        (Ok (getPorts file))


getModuleName : File -> Result Error ModuleName
getModuleName { moduleDefinition } =
    moduleDefinition
        |> Node.value
        |> Module.moduleName
        |> List.Nonempty.fromList
        |> Result.fromMaybe Error.MissingModuleName


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


getDocumentation : Function -> Maybe Documentation
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


getPorts : File -> Ports
getPorts file =
    []
