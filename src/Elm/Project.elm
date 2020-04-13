module Elm.Project exposing (Project, ProjectFile, ProjectFilePath, init, isProjectFile, readFile, readFileWithNamespace, updateFile)

import Dict exposing (Dict)
import Elm.ModulePath as ModulePath exposing (ModuleNamespace, ModulePath)
import Elm.Parser as Parser
import Elm.Processing as Processing
import Elm.Syntax.File exposing (File)
import Main.Error as Error exposing (Error(..))
import Maybe.Extra
import Parser exposing (DeadEnd, Problem(..))


{-| Platform agnostic represenation of a directory path, for example
`["src", "elm"]` for the directory "src/elm"
-}
type alias DirPath =
    List String


{-| Data about a file in the Elm project.

  - `sourceDirectory` is one of the directories specified in the `elm.json` file.

  - `modulePath` is the name of the module and namespace that module lives in.

  - `contents` is the full module source read from the file. If we know that
    the file exists, but have not yet read the file into the Project, then
    `contents` is `Nothing`.

A `ProjectFile` that reflects a file on disc might look something like

    { sourceDirectory = [ "src" ]
    , path = ( [ "Nested", "Directories" ], "File" )
    , contents = Just "module Nested.Directories.Files exposing ..."
    }

-}
type alias ProjectFile =
    { sourceDirectory : DirPath
    , modulePath : ModulePath
    , contents : Maybe String
    }


{-| The location of a `ProjectFile`.
-}
type alias ProjectFilePath =
    { sourceDirectory : DirPath
    , modulePath : ModulePath
    }


{-| All of the Elm modules that are accessible to `elm make` for a given Elm
project. Some subset of these files will be read and parsed to create a
declaration file.
-}
type alias Project =
    Dict ModulePath ProjectFile


{-| A `Project` is initialized with the locations of all known files in the
project, although the contents of these files may not have been read yet.
-}
init : List ProjectFile -> Project
init files =
    files |> List.map (\file -> ( file.modulePath, file )) |> Dict.fromList


updateFile : ProjectFile -> Project -> Project
updateFile projectFile project =
    Dict.insert projectFile.modulePath projectFile project


readFile : ModulePath -> Project -> Result Error File
readFile modulePath project =
    case Dict.get modulePath project of
        Nothing ->
            Err (Fatal (Error.FileNotFound { modulePath = modulePath }))

        Just projectFile ->
            projectFile.contents
                |> Result.fromMaybe
                    (NonFatal
                        (Error.FileNotRead
                            { sourceDirectory = projectFile.sourceDirectory
                            , modulePath = projectFile.modulePath
                            }
                        )
                    )
                |> Result.andThen parse


readFileWithNamespace : ModuleNamespace -> Project -> Result Error File
readFileWithNamespace moduleNamespace project =
    ModulePath.fromNamespace moduleNamespace
        |> Result.fromMaybe (Fatal Error.EmptyFilePath)
        |> Result.andThen (\modulePath -> readFile modulePath project)


isProjectFile : ModulePath -> Project -> Bool
isProjectFile modulePath project =
    Dict.get modulePath project |> Maybe.Extra.isJust


{-| Parse module code and produce an `Elm.Syntax.File` AST, or fail with a
parsing related error message. Each module is parsed in it's own
`ProcessContext`. A context can be extended with additional files to ensure
parsing is accurate, but this use case doesn't seem to be relevant for the
specific task of collecting interop details. See for details:
<https://package.elm-lang.org/packages/stil4m/elm-syntax/7.1.1/Elm-Processing>
-}
parse : String -> Result Error File
parse code =
    code
        |> Parser.parse
        |> Result.map (Processing.process Processing.init)
        |> Result.mapError
            (\err ->
                if isMissingModuleDefinitionError err then
                    Fatal Error.MissingModuleDefinition

                else
                    Fatal Error.ParsingFailure
            )


{-| While `elm make` allows for modules without a module definition in
some cases, `elm-syntax` fails to parse in this situation. It's worth
calling out this specific case, since most other parsing errors will
also produce a helpful error message through `elm-make`.
-}
isMissingModuleDefinitionError : List DeadEnd -> Bool
isMissingModuleDefinitionError deadEnds =
    List.any
        (\{ problem } ->
            List.member problem [ Expecting "module", Expecting "port", Expecting "effect" ]
        )
        deadEnds
