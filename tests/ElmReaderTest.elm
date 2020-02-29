module ElmReaderTest exposing (..)

import Elm.Reader exposing (readModule)
import Error exposing (Error)
import ExampleModules
import Expect
import String.Interpolate exposing (interpolate)
import Test exposing (..)


suite : Test
suite =
    describe "The Elm.Reader module"
        [ describe "Elm.Reader.readModule"
            [ test "extracts the name of a module" <|
                \_ ->
                    Expect.equal
                        (readModule ExampleModules.counter)
                        (Ok { moduleName = "Counter" })
            , test "fail when module doesn't state name" <|
                \_ ->
                    Expect.equal
                        (readModule ExampleModules.noModuleStatement)
                        (Err (Error.Parsing "No module name found"))
            ]
        ]
