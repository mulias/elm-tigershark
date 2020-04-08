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


type alias Model =
    { project : Project
    , filesToProcess : List ProjectFilePath
    , declarations : List ProgramDeclaration
    , declarationFileConfig : DeclarationFile.Config
    }


type Msg
    = FileFetched ProjectFile


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init { inputFilePaths, projectFiles, tsModule } =
    { project = Project.init projectFiles
    , filesToProcess = inputFilePaths
    , declarations = []
    , declarationFileConfig = { declareInModule = tsModule }
    }
        |> processInputFiles
        |> performSideEffects


update : Msg -> Model -> ( Model, Cmd Msg )
update (FileFetched projectFile) model =
    { model | project = Project.updateFile projectFile model.project }
        |> processInputFiles
        |> performSideEffects


subscriptions : model -> Sub Msg
subscriptions =
    always (fileFetched FileFetched)


processInputFiles : Model -> Result ( Error, Model ) Model
processInputFiles model =
    let
        { project, filesToProcess, declarations } =
            model
    in
    case filesToProcess of
        [] ->
            Ok model

        { modulePath } :: restFiles ->
            case generateProgramDeclaration project modulePath of
                Ok declaration ->
                    Ok { model | declarations = declaration :: declarations }

                Err Error.MissingMainFunction ->
                    Ok { model | filesToProcess = restFiles }

                Err error ->
                    Err ( error, model )


generateProgramDeclaration : Project -> ModulePath -> Result Error ProgramDeclaration
generateProgramDeclaration project modulePath =
    Project.readFile modulePath project
        |> Result.andThen ProgramInterface.fromFile
        |> Result.map (ProgramInterface.addImportedPorts project)
        |> Result.andThen (Interop.fromProgramInterface project)
        |> Result.map ProgramDeclaration.fromInterop


performSideEffects : Result ( Error, Model ) Model -> ( Model, Cmd Msg )
performSideEffects result =
    case result of
        Ok model ->
            let
                { declarations, declarationFileConfig } =
                    model
            in
            if List.isEmpty declarations then
                ( model, reportError (Error.toString Error.MissingMainFunction) )

            else
                ( model, writeFile (DeclarationFile.write declarationFileConfig declarations) )

        Err ( Error.FileNotRead filePath, model ) ->
            ( model, fetchFile filePath )

        Err ( error, model ) ->
            ( model, reportError (Error.toString error) )


port writeFile : String -> Cmd msg


port reportError : String -> Cmd msg


port fetchFile : ProjectFilePath -> Cmd msg


port fileFetched : (ProjectFile -> msg) -> Sub msg
