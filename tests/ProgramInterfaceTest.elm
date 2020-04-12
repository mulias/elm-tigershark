module ProgramInterfaceTest exposing (..)

{-| Test that given a module which is supposed to define a `main` of type
`Program`, we successfully extract the details needed to build typescript
types, or return an appropriate error.
-}

import Elm.AST exposing (TypeAnnotationAST(..))
import Elm.ElmDoc exposing (docComment)
import Elm.PortModule exposing (PortModule(..))
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project
import Error exposing (Error(..))
import ExampleModules
import Expect
import String.Interpolate exposing (interpolate)
import Test exposing (..)


{-| The ProjectInterface record keeps a reference to the project module's AST
for convenience, but there isn't value in testing that part of the output.
-}
dropFileFromProgramInterface p =
    { modulePath = p.modulePath
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
                                { modulePath = ( [], "Counter" )
                                , docs = Just (docComment "Counter program. `startingNum` sets the initial count.")
                                , flags = RecordAST [ ( "startingNum", TypedAST ( [], "Int" ) [] ) ]
                                , ports =
                                    ModuleWithPorts
                                        [ { name = "alert"
                                          , typeAnnotation =
                                                FunctionTypeAnnotationAST
                                                    (TypedAST ( [], "String" ) [])
                                                    (TypedAST ( [], "Cmd" ) [ GenericTypeAST "msg" ])
                                          , declaredInModule = [ "Counter" ]
                                          }
                                        ]
                                }

                        result =
                            Project.init
                                [ { sourceDirectory = [ "src" ]
                                  , modulePath = ( [], "Counter" )
                                  , contents = Just ExampleModules.counter
                                  }
                                ]
                                |> Project.readFile ( [], "Counter" )
                                |> Result.andThen ProgramInterface.fromFile
                                |> Result.map dropFileFromProgramInterface
                    in
                    Expect.equal expect result
            , test "fail when the module code is invalid" <|
                \_ ->
                    let
                        expect =
                            Err (Fatal Error.ParsingFailure)

                        result =
                            Project.init
                                [ { sourceDirectory = [ "src" ]
                                  , modulePath = ( [], "BadSadCode" )
                                  , contents = Just ExampleModules.parsingFailure
                                  }
                                ]
                                |> Project.readFile ( [], "BadSadCode" )
                                |> Result.andThen ProgramInterface.fromFile
                    in
                    Expect.equal expect result
            , test "fail when the module definition is missing" <|
                \_ ->
                    let
                        expect =
                            Err (Fatal Error.MissingModuleDefinition)

                        result =
                            Project.init
                                [ { sourceDirectory = [ "src" ]
                                  , modulePath = ( [], "Main" )
                                  , contents = Just ExampleModules.missingModuleDefinition
                                  }
                                ]
                                |> Project.readFile ( [], "Main" )
                                |> Result.andThen ProgramInterface.fromFile
                    in
                    Expect.equal expect result
            , test "fail when the module does not have a main function" <|
                \_ ->
                    let
                        expect =
                            Err (NonFatal Error.MissingMainFunction)

                        result =
                            Project.init
                                [ { sourceDirectory = [ "src" ]
                                  , modulePath = ( [], "NoMain" )
                                  , contents = Just ExampleModules.missingMainFunction
                                  }
                                ]
                                |> Project.readFile ( [], "NoMain" )
                                |> Result.andThen ProgramInterface.fromFile
                    in
                    Expect.equal expect result
            , test "fail when the main function does not have a signature" <|
                \_ ->
                    let
                        expect =
                            Err (Fatal Error.MissingMainSignature)

                        result =
                            Project.init
                                [ { sourceDirectory = [ "src" ]
                                  , modulePath = ( [], "NoMainSig" )
                                  , contents = Just ExampleModules.missingMainSignature
                                  }
                                ]
                                |> Project.readFile ( [], "NoMainSig" )
                                |> Result.andThen ProgramInterface.fromFile
                    in
                    Expect.equal expect result
            ]
        ]
