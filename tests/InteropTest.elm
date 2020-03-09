module InteropTest exposing (..)

import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project exposing (FindBy(..))
import ExampleModules
import Expect
import Test exposing (..)
import TypeScript.ProgramDeclaration as ProgramDeclaration


suite : Test
suite =
    describe "The Elm.Interop module"
        [ describe "Elm.Interop.flagsType"
            [ test "Converts a RecordAST to an Interop type" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleParents = []
                                , moduleName = "Counter"
                                , docs = Just "/** Counter program. `startingNum` sets the initial count. */"
                                , flags = Just "{startingNum: number}"
                                , ports =
                                    [ { name = "alert"
                                      , body = "subscribe(callback: (data: string) => void): void"
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
                                |> Result.andThen ProgramDeclaration.assemble
                    in
                    Expect.equal expected result
            ]
        ]
