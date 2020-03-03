module Elm.ModuleCache exposing (fromList, readModule)

{-| Lazy evaluate and persist Elm module ASTs. While collecting ports and
resolving types it map be necessary to parse and then search through modules
that are imported by the program module, or modules imported by modules
imported by the program module, etc. The ModuleCache allows for only parsing
modules as needed, and persisting the parsed files for re-reading.
-}

import Dict exposing (Dict)
import Elm.Parser as Parser
import Elm.Processing as Processing
import Elm.Syntax.File exposing (File)
import Error exposing (Error)
import Parser exposing (DeadEnd, Problem(..))


{-| A file name relative to an elm `source-directory` entry. For example, for
a file located at 'src/Nested/Directories/File.elm' the `FilePath` is
'Nested/Directories/File.elm'.
-}
type alias FilePath =
    String


{-| The fully qualified name of a module. For example, for a module with
`FilePath` of 'Nested/Directories/File.elm' the `ModuleKey` is
`Nested.Directories.File`.
-}
type alias ModuleKey =
    String


{-| Full contents of an Elm file.
-}
type alias ModuleSource =
    String


{-| Data about an Elm module, with a `file` field which is `Nothing` if the
module has not yet been read with `readModule`, or `Just File` if the module
source has been parsed and saved.
-}
type alias FileThunk =
    { filePath : FilePath
    , source : ModuleSource
    , file : Maybe File
    }


{-| A cache of parsed and unparsed modules in the elm project.
-}
type alias ModuleCache =
    Dict ModuleKey FileThunk


{-| Create a new cache. The cache should be initialized with every file in the
elm project, although not all files will necessarily be parsed.
-}
fromList : List ( FilePath, ModuleSource ) -> ModuleCache
fromList modules =
    List.foldl
        (\( filePath, moduleContent ) acc ->
            Dict.insert
                (filePathToKey filePath)
                (fileThunk filePath moduleContent)
                acc
        )
        Dict.empty
        modules


fileThunk : FilePath -> ModuleSource -> FileThunk
fileThunk filePath source =
    { filePath = filePath
    , source = source
    , file = Nothing
    }


{-| Given a file name relative to an elm `source-directory` entry, make the
name of the Elm module. For example, to get the module name for a file located
at 'src/Nested/Directories/File.elm', we pass 'Nested/Directories/File.elm' as
the `filePath`, and the returned value should be 'Nested.Directories.File'.
TODO: Support windows file paths?
-}
filePathToKey : FilePath -> ModuleKey
filePathToKey filePath =
    filePath
        |> String.replace "/" "."
        |> String.replace ".elm" ""


{-| Get the parsed File for a module. Returns an error if the module is not
found in the cache, or if the module source fails to parse.
-}
readModule : ModuleKey -> ModuleCache -> Result Error ( File, ModuleCache )
readModule moduleKey graph =
    Dict.get moduleKey graph
        |> Result.fromMaybe Error.ImportedModuleNotFound
        |> Result.andThen
            (\thunk ->
                case thunk.file of
                    Just readFile ->
                        Ok ( readFile, graph )

                    Nothing ->
                        Result.map
                            (\readFile ->
                                ( readFile
                                , Dict.insert moduleKey
                                    { thunk | file = Just readFile }
                                    graph
                                )
                            )
                            (parse thunk.source)
            )


{-| Parse module code and produce an `Elm.Syntax.File` AST, or fail with a
parsing related error message. Each module is parsed in it's own
`ProcessContext`. A context can be extended with additional files to ensure
parsing is accurate, but this use case doesn't seem to be relevant for the
specific task of collecting interop details. See for details:
<https://package.elm-lang.org/packages/stil4m/elm-syntax/7.1.1/Elm-Processing>
-}
parse : ModuleSource -> Result Error File
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
