module InteropTest exposing (..)

import Elm.Interop as Interop exposing (Interop(..), PortInterop(..))
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project
import ExampleModules
import Expect
import Test exposing (..)
import TypeScript.ProgramDeclaration as ProgramDeclaration


suite : Test
suite =
    describe "The Elm.Interop module"
        [ describe "Elm.Interop.program"
            [ test "Converts an Elm ProgramInterface to interoperable types and strings" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleParents = []
                                , moduleName = "Counter"
                                , docs = Just "Counter program. `startingNum` sets the initial count."
                                , flags = RecordType [ ( "startingNum", NumberType ) ]
                                , ports =
                                    [ OutboundPort
                                        { name = "alert"
                                        , outType = StringType
                                        }
                                    ]
                                }

                        project =
                            Project.init [ { sourceDirectory = [ "src" ], modulePath = ( [], "Counter" ), contents = Just ExampleModules.counter } ]

                        result =
                            Project.readFile ( [], "Counter" ) project
                                |> Result.andThen ProgramInterface.fromFile
                                |> Result.andThen (Interop.fromProgramInterface project)
                    in
                    Expect.equal expected result
            ]
        ]
