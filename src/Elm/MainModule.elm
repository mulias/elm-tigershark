module Elm.MainModule exposing (extract, parse)

{-| Parse an Elm module and collect the parts of the AST relevant to the
TypeScript declaration file.
-}

import Elm.AST exposing (SignatureAST, toSignatureAST)
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
import Util.Parser exposing (isMissingModuleDefinitionError)


type alias ModuleName =
    Nonempty String


type alias Ports =
    List SignatureAST


type alias MainModule =
    { moduleName : ModuleName
    , mainSignature : SignatureAST
    , mainDocumentation : Maybe Documentation
    , ports : Ports
    }


parse : String -> Result Error File
parse code =
    code
        |> Parser.parse
        |> Result.map (Processing.process Processing.init)
        |> Result.mapError
            (\err ->
                if isMissingModuleDefinitionError err then
                    Error.MissingModuleDefinition

                else
                    Error.ParsingFailure
            )


extract : File -> Result Error MainModule
extract file =
    Result.map3
        (\moduleName ( mainSignature, mainDocumentation ) ports ->
            { moduleName = moduleName
            , mainSignature = mainSignature
            , mainDocumentation = mainDocumentation
            , ports = ports
            }
        )
        (getModuleName file)
        (getMain file)
        (getPorts file)


getModuleName : File -> Result Error ModuleName
getModuleName { moduleDefinition } =
    moduleDefinition
        |> Node.value
        |> Module.moduleName
        |> List.Nonempty.fromList
        |> Result.fromMaybe Error.MissingModuleName


getMain : File -> Result Error ( SignatureAST, Maybe Documentation )
getMain { declarations } =
    declarations
        |> Util.List.findMap getMainFromNode
        |> Result.fromMaybe Error.MissingMainFunction
        |> Result.andThen
            (\{ documentation, signature } ->
                case signature of
                    Just sigNode ->
                        Ok ( toSignatureAST (Node.value sigNode), Maybe.map Node.value documentation )

                    Nothing ->
                        Err Error.MissingMainSignature
            )


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


getPorts : File -> Result Error Ports
getPorts file =
    Ok []
