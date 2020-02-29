module TypeScriptWriterTest exposing (..)

import Expect
import String.Interpolate exposing (interpolate)
import Test exposing (..)
import TypeScript.Writer exposing (writeDeclarationFile)


simpleDeclarationFile : String -> String
simpleDeclarationFile moduleName =
    interpolate """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for Elm ports

export namespace Elm {
  namespace {0} {
    export interface App {
      ports: {};
    }
    export function init(options: {
      node?: HTMLElement | null;
    }): Elm.{0}.App;
  }
}""" [ moduleName ]


suite : Test
suite =
    describe "The Typescript.Writer module"
        [ describe "Typescript.Writer.writeDeclarationFile"
            [ test "generates a simple declaration file" <|
                \_ ->
                    let
                        moduleName =
                            "Tigershark"
                    in
                    Expect.equal
                        (writeDeclarationFile moduleName)
                        (simpleDeclarationFile moduleName)
            ]
        ]
