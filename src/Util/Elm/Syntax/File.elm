module Util.Elm.Syntax.File exposing (fileModuleName, moduleExposes)

import Elm.AST exposing (ExposingAST(..), toExposingAST)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module
import Elm.Syntax.Node as Node


fileModuleName : File -> List String
fileModuleName file =
    file.moduleDefinition |> Node.value |> Module.moduleName


moduleExposes : File -> String -> Bool
moduleExposes file declarationName =
    case
        file.moduleDefinition
            |> Node.value
            |> Module.exposingList
            |> toExposingAST
    of
        All ->
            True

        Explicit list ->
            List.member declarationName list
