module TypeScript.Writer exposing (writeDeclarationFile)

{-| Take the MainModule extracted from the elm files and construct a TypeScript
declaration file.
-}

import String.Interpolate exposing (interpolate)


type alias DeclarationFileContent =
    { namespace : String
    , docs : String
    , flags : String
    , ports : String
    }


{-| Add a warning header to each declaration file.
-}
prefix : String
prefix =
    """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for Elm ports"""


{-| Given formatted strings, construct the full file.
-}
writeDeclarationFile : DeclarationFileContent -> String
writeDeclarationFile { namespace, docs, flags, ports } =
    interpolate """{0}

export namespace Elm {{1}
  namespace {2} {
    export interface App {
      ports: {3}
    }
    export function init(options: {
      node?: HTMLElement | null;{4}
    }): Elm.{2}.App;
  }
}"""
        [ prefix, docs, namespace, ports, flags ]
