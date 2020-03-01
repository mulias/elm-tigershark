module MainModuleTest exposing (..)

import Elm.AST exposing (TypeAnnotationAST(..))
import Elm.MainModule as MainModule
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
                                , mainSignature =
                                    { name = "main"
                                    , typeAnnotation =
                                        TypedAST
                                            ( [], "Program" )
                                            [ UnitAST
                                            , TypedAST ( [], "Int" ) []
                                            , TypedAST ( [], "Msg" ) []
                                            ]
                                    }
                                , mainDocumentation = Nothing
                                , ports = []
                                }

                        result =
                            ExampleModules.counter
                                |> MainModule.parse
                                |> Result.andThen MainModule.extract
                    in
                    Expect.equal expect result
            , test "fail when the module code is invalid" <|
                \_ ->
                    let
                        expect =
                            Err Error.ParsingFailure

                        result =
                            ExampleModules.parsingFailure
                                |> MainModule.parse
                                |> Result.andThen MainModule.extract
                    in
                    Expect.equal expect result
            , test "fail when the module definition is missing" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingModuleDefinition

                        result =
                            ExampleModules.missingModuleDefinition
                                |> MainModule.parse
                                |> Result.andThen MainModule.extract
                    in
                    Expect.equal expect result
            , test "fail when the module does not have a main function" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingMainFunction

                        result =
                            ExampleModules.missingMainFunction
                                |> MainModule.parse
                                |> Result.andThen MainModule.extract
                    in
                    Expect.equal expect result
            , test "fail when the main function does not have a signature" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingMainSignature

                        result =
                            ExampleModules.missingMainSignature
                                |> MainModule.parse
                                |> Result.andThen MainModule.extract
                    in
                    Expect.equal expect result
            , skip <|
                test "Nested main module is unsupported" <|
                    \_ ->
                        let
                            expect =
                                Err Error.NestedMainModuleUnsupported

                            result =
                                ExampleModules.nestedMainModuleUnsupported
                                    |> MainModule.parse
                                    |> Result.andThen MainModule.extract
                        in
                        Expect.equal expect result
            ]
        ]
