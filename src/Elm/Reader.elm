module Elm.Reader exposing (readModule)

import Elm.Parser as Parser
import Elm.Parser.Error exposing (errorMessage)
import Elm.RawFile as RawFile
import Elm.Syntax.ModuleName exposing (ModuleName)
import Error exposing (Error)
import Parser exposing (deadEndsToString)


type alias Module =
    { moduleName : String
    }


readModule : String -> Result Error Module
readModule fileContent =
    case Parser.parse fileContent of
        Err errs ->
            Err (Error.Parsing (errorMessage errs))

        Ok raw ->
            raw
                |> RawFile.moduleName
                |> unnestedModuleName
                |> Result.map Module


unnestedModuleName : ModuleName -> Result Error String
unnestedModuleName moduleNamePath =
    case moduleNamePath of
        [] ->
            Err (Error.Parsing "No module name found")

        [ name ] ->
            Ok name

        _ ->
            Err (Error.Unsupported "Nested main modules not supported")
