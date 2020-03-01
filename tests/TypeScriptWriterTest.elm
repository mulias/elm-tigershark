module TypeScriptWriterTest exposing (..)

import Expect
import String.Interpolate exposing (interpolate)
import Test exposing (..)
import TypeScript.Writer exposing (writeDeclarationFile)


simpleDeclarationFile : String
simpleDeclarationFile =
    """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for Elm ports

export namespace Elm {
  /** The Tigershark main */
  namespace Tigershark {
    export interface App {
      ports: {};
    }
    export function init(options: {
      node?: HTMLElement | null;
      flags: { numSharks: number };
    }): Elm.Tigershark.App;
  }
}"""


suite : Test
suite =
    describe "The Typescript.Writer module"
        [ describe "Typescript.Writer.writeDeclarationFile"
            [ test "creates a declaration file from formatted strings" <|
                \_ ->
                    let
                        content =
                            { namespace = "Tigershark"
                            , docs = "\n  /** The Tigershark main */"
                            , flags = "\n      flags: { numSharks: number };"
                            , ports = "{};"
                            }
                    in
                    Expect.equal
                        (writeDeclarationFile content)
                        simpleDeclarationFile
            ]
        ]
