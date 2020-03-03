module ProgramInterfaceTest exposing (..)

{-| Test that given a module which is supposed to define a `main` of type
`Program`, we successfully extract the details needed to build typescript
types, or return an appropriate error.
-}

import Elm.AST exposing (TypeAnnotationAST(..))
import Elm.ModuleCache as ModuleCache
import Elm.ProgramInterface as ProgramInterface
import Error exposing (Error)
import ExampleModules
import Expect
import String.Interpolate exposing (interpolate)
import Test exposing (..)


suite : Test
suite =
    describe "The Elm.Reader module"
        [ describe "Elm.ProgramInterface.extract"
            [ test "Collects module information needed for TS generation" <|
                \_ ->
                    let
                        expect =
                            Ok
                                { moduleParents = []
                                , moduleName = "Counter"
                                , docs = Just "{-| Counter program. `startingNum` sets the initial count.\n-}"
                                , flags = RecordAST [ ( "startingNum", TypedAST ( [], "Int" ) [] ) ]
                                , ports =
                                    [ { name = "alert"
                                      , typeAnnotation =
                                            FunctionTypeAnnotationAST
                                                (TypedAST ( [], "String" ) [])
                                                (TypedAST ( [], "Cmd" ) [ GenericTypeAST "msg" ])
                                      }
                                    ]
                                }

                        result =
                            ModuleCache.fromList [ ( "Counter", ExampleModules.counter ) ]
                                |> ModuleCache.readModule "Counter"
                                |> Result.andThen (Tuple.first >> ProgramInterface.extract)
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
                                |> Result.andThen (Tuple.first >> ProgramInterface.extract)
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
                                |> Result.andThen (Tuple.first >> ProgramInterface.extract)
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
                                |> Result.andThen (Tuple.first >> ProgramInterface.extract)
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
                                |> Result.andThen (Tuple.first >> ProgramInterface.extract)
                    in
                    Expect.equal expect result
            ]
        ]
