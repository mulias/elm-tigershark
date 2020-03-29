port module Main exposing (main)

import Elm.Interop as Interop
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project exposing (FindBy(..), ProjectFile)
import Error
import TypeScript.DeclarationFile as DeclarationFile
import TypeScript.ProgramDeclaration as ProgramDeclaration


type alias Flags =
    { inputFilePath : String
    , projectFiles : List ProjectFile
    }


main : Program Flags () ()
main =
    Platform.worker
        { init = init
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


init : { inputFilePath : String, projectFiles : List ProjectFile } -> ( (), Cmd msg )
init { inputFilePath, projectFiles } =
    let
        project =
            Project.init projectFiles
    in
    case
        Project.readFileWith (FilePath inputFilePath) project
            |> Result.andThen ProgramInterface.fromFile
            |> Result.map (ProgramInterface.addImportedPorts project)
            |> Result.andThen (Interop.fromProgramInterface project)
            |> Result.map ProgramDeclaration.fromInterop
            |> Result.map List.singleton
            |> Result.map DeclarationFile.write
    of
        Ok outputFile ->
            ( (), writeFile outputFile )

        Err error ->
            ( (), reportError (Error.toString error) )


port writeFile : String -> Cmd msg


port reportError : String -> Cmd msg
