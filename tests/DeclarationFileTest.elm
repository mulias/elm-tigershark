module DeclarationFileTest exposing (..)

{-| Test that given the stringified components of a declaration file, we can
correctly assemble the output.
-}

import Expect
import String.Interpolate exposing (interpolate)
import Test exposing (..)
import TypeScript.DeclarationFile as DeclarationFile


simpleDeclarationFile : String
simpleDeclarationFile =
    """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for Elm ports

export namespace Elm {
  /** The Tigershark Elm program */
  namespace Tigershark {
    export interface App {
      ports: {
        ping: {
          subscribe(callback: (data: null) => void): void;
        };
        pong: {
          send(data: null): void;
        };
      };
    }
    export function init(options: {
      node?: HTMLElement | null;
      flags: { numSharks: number };
    }): Elm.Tigershark.App;
  }
}"""


suite : Test
suite =
    describe "The Typescript.DeclarationFile module"
        [ describe "Typescript.DeclarationFile.write"
            [ test "creates a declaration file from formatted strings" <|
                \_ ->
                    let
                        content =
                            { moduleParents = []
                            , moduleName = "Tigershark"
                            , docs = Just "/** The Tigershark Elm program */"
                            , flags = Just "{ numSharks: number }"
                            , ports =
                                [ { name = "ping", body = "subscribe(callback: (data: null) => void): void" }
                                , { name = "pong", body = "send(data: null): void" }
                                ]
                            }
                    in
                    Expect.equal
                        (DeclarationFile.write content)
                        simpleDeclarationFile
            ]
        ]
