port module Main exposing (main)

import Elm.ModuleCache as Module
import Elm.ProgramInterface as ProgramInterface
import Error
import TypeScript.DeclarationFile as DeclarationFile
import TypeScript.Interop exposing (toProgramDeclaration)


main : Program { inputFileSource : String } () ()
main =
    Platform.worker
        { init = init
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


init : { inputFileSource : String } -> ( (), Cmd msg )
init { inputFileSource } =
    case
        Module.parse inputFileSource
            |> Result.andThen ProgramInterface.extract
            |> Result.andThen toProgramDeclaration
            |> Result.map List.singleton
            |> Result.map DeclarationFile.write
    of
        Ok outputFile ->
            ( (), writeFile outputFile )

        Err error ->
            ( (), reportError (Error.toString error) )


port writeFile : String -> Cmd msg


port reportError : String -> Cmd msg
