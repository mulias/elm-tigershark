module TypeScript.Writer exposing (writeDeclarationFile)

import String.Interpolate exposing (interpolate)


prefix : String
prefix =
    """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for Elm ports"""


writeDeclarationFile : String -> String
writeDeclarationFile moduleName =
    interpolate """{0}

export namespace Elm {
  namespace {1} {
    export interface App {
      ports: {};
    }
    export function init(options: {
      node?: HTMLElement | null;
    }): Elm.{1}.App;
  }
}"""
        [ prefix, moduleName ]
