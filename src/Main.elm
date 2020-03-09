port module Main exposing (main)

import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project exposing (FindBy(..), ProjectFile)
import Error
import TypeScript.DeclarationFile as DeclarationFile
import TypeScript.ProgramDeclaration as ProgramDeclaration


main : Program { inputFilePath : String, projectFiles : List { sourceDirectory : String, filePath : String, contents : String } } () ()
main =
    Platform.worker
        { init = init
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


init : { inputFilePath : String, projectFiles : List ProjectFile } -> ( (), Cmd msg )
init { inputFilePath, projectFiles } =
    case
        Project.init projectFiles
            |> Project.readFileWith (FilePath inputFilePath)
            |> Result.andThen ProgramInterface.extract
            |> Result.andThen ProgramDeclaration.assemble
            |> Result.map List.singleton
            |> Result.map DeclarationFile.write
    of
        Ok outputFile ->
            ( (), writeFile outputFile )

        Err error ->
            ( (), reportError (Error.toString error) )


port writeFile : String -> Cmd msg


port reportError : String -> Cmd msg
