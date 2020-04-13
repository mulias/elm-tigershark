port module Main.Program exposing (main)

import Elm.Interop as Interop
import Elm.ModulePath exposing (ModulePath)
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project exposing (Project, ProjectFile, ProjectFilePath)
import Elm.Syntax.File exposing (File)
import Main.Error as Error exposing (Error(..))
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


update : Msg -> Model -> ( Model, Cmd Msg )
update (FileFetched projectFile) model =
    { model | project = Project.updateFile projectFile model.project }
        |> processInputFiles


subscriptions : model -> Sub Msg
subscriptions =
    always (fileFetched FileFetched)


processInputFiles : Model -> ( Model, Cmd Msg )
processInputFiles model =
    let
        { project, filesToProcess, declarations, declarationFileConfig } =
            model
    in
    case filesToProcess of
        [] ->
            if List.isEmpty declarations then
                ( model, reportError (Error.toString Error.NoDeclarationsToGenerate) )

            else
                ( model, writeFile (DeclarationFile.write declarationFileConfig declarations) )

        { modulePath } :: restFiles ->
            case generateProgramDeclaration project modulePath of
                Ok declaration ->
                    processInputFiles
                        { model
                            | filesToProcess = restFiles
                            , declarations = declaration :: declarations
                        }

                Err (NonFatal Error.MissingMainFunction) ->
                    processInputFiles
                        { model
                            | filesToProcess = restFiles
                        }

                Err (NonFatal (Error.FileNotRead filePath)) ->
                    ( model, fetchFile filePath )

                Err (Fatal error) ->
                    ( model, reportError (Error.toString error) )


generateProgramDeclaration : Project -> ModulePath -> Result Error ProgramDeclaration
generateProgramDeclaration project modulePath =
    Project.readFile modulePath project
        |> Result.andThen (ProgramInterface.fromFile project)
        |> Result.andThen (Interop.fromProgramInterface project)
        |> Result.map ProgramDeclaration.fromInterop


port writeFile : String -> Cmd msg


port reportError : String -> Cmd msg


port fetchFile : ProjectFilePath -> Cmd msg


port fileFetched : (ProjectFile -> msg) -> Sub msg
