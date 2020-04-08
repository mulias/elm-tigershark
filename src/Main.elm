port module Main exposing (main)

import Elm.Interop as Interop
import Elm.ModulePath exposing (ModulePath)
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project exposing (Project, ProjectFile, ProjectFilePath)
import Elm.Syntax.File exposing (File)
import Error exposing (Error)
import Result.Extra
import TypeScript.DeclarationFile as DeclarationFile
import TypeScript.ProgramDeclaration as ProgramDeclaration exposing (ProgramDeclaration)


type alias Flags =
    { inputFilePaths : List ProjectFilePath
    , projectFiles : List ProjectFile
    , tsModule : Maybe String
    }


main : Program Flags () ()
main =
    Platform.worker
        { init = init
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


init : Flags -> ( (), Cmd msg )
init { inputFilePaths, projectFiles, tsModule } =
    let
        project =
            Project.init projectFiles

        initModel =
            Ok []

        programDeclarations =
            List.foldr (addProgramDeclaration project) initModel inputFilePaths
    in
    case programDeclarations of
        Ok [] ->
            ( (), reportError (Error.toString Error.MissingMainFunction) )

        Ok declarations ->
            ( ()
            , declarations
                |> DeclarationFile.write { declareInModule = tsModule }
                |> writeFile
            )

        Err error ->
            ( (), reportError (Error.toString error) )


addProgramDeclaration : Project -> ProjectFilePath -> Result Error (List ProgramDeclaration) -> Result Error (List ProgramDeclaration)
addProgramDeclaration project { modulePath } computation =
    computation
        |> Result.andThen
            (\declarations ->
                Project.readFile modulePath project
                    |> Result.andThen
                        (\file ->
                            if ProgramInterface.isMainFile file then
                                generateProgramDeclaration project file
                                    |> Result.map (\declaration -> declaration :: declarations)

                            else
                                Ok declarations
                        )
            )


generateProgramDeclaration : Project -> File -> Result Error ProgramDeclaration
generateProgramDeclaration project file =
    ProgramInterface.fromFile file
        |> Result.map (ProgramInterface.addImportedPorts project)
        |> Result.andThen (Interop.fromProgramInterface project)
        |> Result.map ProgramDeclaration.fromInterop


port writeFile : String -> Cmd msg


port reportError : String -> Cmd msg
