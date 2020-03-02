module DeclarationFileTest exposing (..)

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
    describe "The Typescript.Writer module"
        [ describe "Typescript.Writer.writeDeclarationFile"
            [ test "creates a declaration file from formatted strings" <|
                \_ ->
                    let
                        content =
                            { namespace = "Tigershark"
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
