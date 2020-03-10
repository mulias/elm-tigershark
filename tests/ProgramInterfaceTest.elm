module ProgramInterfaceTest exposing (..)

{-| Test that given a module which is supposed to define a `main` of type
`Program`, we successfully extract the details needed to build typescript
types, or return an appropriate error.
-}

import Elm.AST exposing (TypeAnnotationAST(..))
import Elm.ElmDoc exposing (docComment)
import Elm.PortModule exposing (PortModule(..))
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project exposing (FindBy(..))
import Error exposing (Error)
import ExampleModules
import Expect
import String.Interpolate exposing (interpolate)
import Test exposing (..)


{-| The ProjectInterface record keeps a reference to the project module's AST
for convenience, but there isn't value in testing that part of the output.
-}
dropFileFromProgramInterface p =
    { moduleParents = p.moduleParents
    , moduleName = p.moduleName
    , docs = p.docs
    , flags = p.flags
    , ports = p.ports
    }


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
                                , docs = Just (docComment "Counter program. `startingNum` sets the initial count.")
                                , flags = RecordAST [ ( "startingNum", TypedAST ( [], "Int" ) [] ) ]
                                , ports =
                                    ModuleWithPorts
                                        [ { name = "alert"
                                          , typeAnnotation =
                                                FunctionTypeAnnotationAST
                                                    (TypedAST ( [], "String" ) [])
                                                    (TypedAST ( [], "Cmd" ) [ GenericTypeAST "msg" ])
                                          }
                                        ]
                                }

                        result =
                            Project.init
                                [ { sourceDirectory = "src"
                                  , filePath = "Counter.elm"
                                  , contents = ExampleModules.counter
                                  }
                                ]
                                |> Project.readFileWith (FilePath "Counter.elm")
                                |> Result.andThen ProgramInterface.extract
                                |> Result.map dropFileFromProgramInterface
                    in
                    Expect.equal expect result
            , test "fail when the module code is invalid" <|
                \_ ->
                    let
                        expect =
                            Err Error.ParsingFailure

                        result =
                            Project.init
                                [ { sourceDirectory = "src"
                                  , filePath = "BadSadCode.elm"
                                  , contents = ExampleModules.parsingFailure
                                  }
                                ]
                                |> Project.readFileWith (FilePath "BadSadCode.elm")
                                |> Result.andThen ProgramInterface.extract
                    in
                    Expect.equal expect result
            , test "fail when the module definition is missing" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingModuleDefinition

                        result =
                            Project.init
                                [ { sourceDirectory = "src"
                                  , filePath = "Main.elm"
                                  , contents = ExampleModules.missingModuleDefinition
                                  }
                                ]
                                |> Project.readFileWith (FilePath "Main.elm")
                                |> Result.andThen ProgramInterface.extract
                    in
                    Expect.equal expect result
            , test "fail when the module does not have a main function" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingMainFunction

                        result =
                            Project.init
                                [ { sourceDirectory = "src"
                                  , filePath = "NoMain.elm"
                                  , contents = ExampleModules.missingMainFunction
                                  }
                                ]
                                |> Project.readFileWith (FilePath "NoMain.elm")
                                |> Result.andThen ProgramInterface.extract
                    in
                    Expect.equal expect result
            , test "fail when the main function does not have a signature" <|
                \_ ->
                    let
                        expect =
                            Err Error.MissingMainSignature

                        result =
                            Project.init
                                [ { sourceDirectory = "src"
                                  , filePath = "NoMainSig.elm"
                                  , contents = ExampleModules.missingMainSignature
                                  }
                                ]
                                |> Project.readFileWith (FilePath "NoMainSig.elm")
                                |> Result.andThen ProgramInterface.extract
                    in
                    Expect.equal expect result
            ]
        ]
