module Elm.Project exposing (FindBy(..), Project, ProjectFile, hasFileWith, init, readFileWith)

import Dict exposing (Dict)
import Elm.Parser as Parser
import Elm.Processing as Processing
import Elm.Syntax.File exposing (File)
import Error exposing (Error)
import Parser exposing (DeadEnd, Problem(..))


{-| Data about a file in the Elm project.

  - `sourceDirectory` is one of the directories specified in the `elm.json` file.

  - `filePath` is the rest of the path to the file, starting from the
    `sourceDirectory`.

  - `contents` is the full module source read from the file.

A `ProjectFile` that reflects a file on disc might look something like

    { sourceDirectory = 'src'
    , path = 'Nested/Directories/File.elm'
    , contents = "module Nested.Directories.Files exposing ..."
    }

-}
type alias ProjectFile =
    { sourceDirectory : String
    , filePath : String
    , contents : String
    }


{-| The fully name of a module as a string. For example, for a module stored at
'src/Nested/Directories/File.elm' the `ModuleKey` is `Nested.Directories.File`.
In a successfully type-checked Elm project the module name must directly map to
the file path and vice versa.
-}
type alias ModuleKey =
    String


{-| All of the Elm modules that are accessible to `elm make` for a given Elm
project. Some subset of these files will be read and parsed to create a
declaration file.
-}
type alias Project =
    Dict ModuleKey ProjectFile


{-| Specifies the ways a file can be uniquely identified in the Project.
-}
type FindBy
    = FilePath String
    | ModuleName (List String)


init : List ProjectFile -> Project
init files =
    List.foldl
        (\projectFile acc ->
            Dict.insert
                (filePathToKey projectFile.filePath)
                projectFile
                acc
        )
        Dict.empty
        files


filePathToKey : String -> ModuleKey
filePathToKey filePath =
    filePath
        |> String.replace ".elm" ""
        |> String.replace "/" "."


findByToKey : FindBy -> ModuleKey
findByToKey findBy =
    case findBy of
        FilePath path ->
            filePathToKey path

        ModuleName name ->
            String.join "." name


readFileWith : FindBy -> Project -> Result Error File
readFileWith findBy project =
    Dict.get (findByToKey findBy) project
        |> Result.fromMaybe Error.ModuleNotFound
        |> Result.map .contents
        |> Result.andThen parse


hasFileWith : FindBy -> Project -> Bool
hasFileWith findBy project =
    Dict.member (findByToKey findBy) project


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
                    Error.MissingModuleDefinition

                else
                    Error.ParsingFailure
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
