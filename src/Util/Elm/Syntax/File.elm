module Util.Elm.Syntax.File exposing (fileModuleNameList, moduleExposes)

import Elm.AST exposing (ExposingAST(..), toExposingAST)
import Elm.ModulePath exposing (ModuleName)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module
import Elm.Syntax.Node as Node


fileModuleNameList : File -> List ModuleName
fileModuleNameList file =
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
