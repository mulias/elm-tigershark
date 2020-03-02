module MainModuleTest exposing (..)

import Elm.AST exposing (TypeAnnotationAST(..))
import Elm.MainModule as MainModule
import Elm.ModuleCache as ModuleCache
import Error exposing (Error)
import ExampleModules
import Expect
import List.Nonempty
import String.Interpolate exposing (interpolate)
import Test exposing (..)


suite : Test
suite =
    describe "The Elm.Reader module"
        [ describe "Elm.MainModule.extract"
            [ test "Collects module information needed for TS generation" <|
                \_ ->
                    let
                        expect =
                            Ok
                                { moduleName = List.Nonempty.fromElement "Counter"
                                , mainDocumentation = Just "{-| Counter program. `startingNum` sets the initial count.\n-}"
                                , flags = RecordAST [ ( "startingNum", TypedAST ( [], "Int" ) [] ) ]
                                , ports = []
                                }

                        result =
                            ModuleCache.fromList [ ( "Counter", ExampleModules.counter ) ]
                                |> ModuleCache.readModule "Counter"
                                |> Result.andThen (Tuple.first >> MainModule.extract)
                    in
                    Expect.equal expect result
            , test "fail when the module code is invalid" <|
                \_ ->
                    let
                        expect =
                            Err Error.ParsingFailure

                        result =
                            ModuleCache.fromList [ ( "BadSadCode", ExampleModules.parsingFailure ) ]
                                |> ModuleCache.readModule "BadSadCode"
                                |> Result.andThen (Tuple.first >> MainModule.extract)
                    in
                    Expect.equal expect result
            , test "fail when the module definition is missing" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingModuleDefinition

                        result =
                            ModuleCache.fromList [ ( "Main", ExampleModules.missingModuleDefinition ) ]
                                |> ModuleCache.readModule "Main"
                                |> Result.andThen (Tuple.first >> MainModule.extract)
                    in
                    Expect.equal expect result
            , test "fail when the module does not have a main function" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingMainFunction

                        result =
                            ModuleCache.fromList [ ( "NoMain", ExampleModules.missingMainFunction ) ]
                                |> ModuleCache.readModule "NoMain"
                                |> Result.andThen (Tuple.first >> MainModule.extract)
                    in
                    Expect.equal expect result
            , test "fail when the main function does not have a signature" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingMainSignature

                        result =
                            ModuleCache.fromList [ ( "NoMainSig", ExampleModules.missingMainSignature ) ]
                                |> ModuleCache.readModule "NoMainSig"
                                |> Result.andThen (Tuple.first >> MainModule.extract)
                    in
                    Expect.equal expect result
            , skip <|
                test "Nested main module is unsupported" <|
                    \_ ->
                        let
                            expect =
                                Err Error.NestedMainModuleUnsupported

                            result =
                                ModuleCache.fromList [ ( "Nested.Main.Module", ExampleModules.nestedMainModuleUnsupported ) ]
                                    |> ModuleCache.readModule "Nested.Main.Module"
                                    |> Result.andThen (Tuple.first >> MainModule.extract)
                        in
                        Expect.equal expect result
            ]
        ]
