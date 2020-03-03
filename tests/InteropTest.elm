module InteropTest exposing (..)

import Elm.ModuleCache as ModuleCache
import Elm.ProgramInterface as ProgramInterface
import ExampleModules
import Expect
import Test exposing (..)
import TypeScript.Interop exposing (toDeclarationFile)


suite : Test
suite =
    describe "The Elm.Interop module"
        [ describe "Elm.Interop.flagsType"
            [ test "Converts a RecordAST to an Interop type" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleName = "Counter"
                                , docs = Just "/** Counter program. `startingNum` sets the initial count. */"
                                , flags = Just "{startingNum: number}"
                                , ports =
                                    [ { name = "alert"
                                      , body = "subscribe(callback: (data: string) => void): void"
                                      }
                                    ]
                                }

                        result =
                            ModuleCache.fromList [ ( "Counter", ExampleModules.counter ) ]
                                |> ModuleCache.readModule "Counter"
                                |> Result.andThen (Tuple.first >> ProgramInterface.extract)
                                |> Result.andThen toDeclarationFile
                    in
                    Expect.equal expected result
            ]
        ]
