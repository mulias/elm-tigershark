port module Main exposing (main)

import Elm.Interop as Interop
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project exposing (FindBy(..), Project, ProjectFile)
import Elm.Syntax.File exposing (File)
import Error exposing (Error)
import Result.Extra
import TypeScript.DeclarationFile as DeclarationFile
import TypeScript.ProgramDeclaration as ProgramDeclaration exposing (ProgramDeclaration)


type alias Flags =
    { inputFilePaths : List String
    , projectFiles : List ProjectFile
    }


main : Program Flags () ()
main =
    Platform.worker
        { init = init
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


init : Flags -> ( (), Cmd msg )
init { inputFilePaths, projectFiles } =
    let
        project =
            Project.init projectFiles
    in
    case
        inputFilePaths
            |> List.map (\filePath -> Project.readFileWith (FilePath filePath) project)
            |> Result.Extra.combine
            |> Result.andThen
                (\files ->
                    List.filter ProgramInterface.isMainFile files
                        |> List.map (generateProgramDeclaration project)
                        |> Result.Extra.combine
                )
            |> Result.map DeclarationFile.write
    of
        Ok outputFile ->
            ( (), writeFile outputFile )

        Err error ->
            ( (), reportError (Error.toString error) )


generateProgramDeclaration : Project -> File -> Result Error ProgramDeclaration
generateProgramDeclaration project file =
    ProgramInterface.fromFile file
        |> Result.map (ProgramInterface.addImportedPorts project)
        |> Result.andThen (Interop.fromProgramInterface project)
        |> Result.map ProgramDeclaration.fromInterop


port writeFile : String -> Cmd msg


port reportError : String -> Cmd msg
