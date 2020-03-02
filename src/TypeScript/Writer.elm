module TypeScript.Writer exposing (blankLine, file, initFn, namespace, ports, prefix, toString)

{-| Take the MainModule extracted from the elm files and construct a TypeScript
declaration file.
-}

import String.Interpolate exposing (interpolate)


type Writer
    = Writer { format : List String -> String, children : List Writer }


toString : Writer -> String
toString (Writer { format, children }) =
    children
        |> List.map toString
        |> format


file : List Writer -> Writer
file children =
    Writer { format = String.join "\n", children = children }


blankLine : Writer
blankLine =
    Writer { format = always "", children = [] }


prefix : Writer
prefix =
    let
        content =
            """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for Elm ports"""
    in
    Writer { format = always content, children = [] }


namespace : { name : String, docs : Maybe String } -> List Writer -> Writer
namespace { name, docs } children =
    let
        docStr =
            docs
                |> Maybe.map (\str -> str ++ "\n")
                |> Maybe.withDefault ""
    in
    Writer
        { format =
            \contents ->
                interpolate "{0}export namespace {1} {\n{2}\n}"
                    [ docStr, name, indented 2 (String.join "\n" contents) ]
        , children = children
        }


ports : List { name : String, body : String } -> Writer
ports portDefs =
    let
        content =
            if List.isEmpty portDefs then
                "ports: {};"

            else
                "ports: {\n" ++ String.join "\n" portDefs ++ "\n};"
    in
    Writer { format = always content, children = [] }


initFn : String -> Maybe String -> Writer
initFn name flags =
    let
        flagsStr =
            flags
                |> Maybe.map (\str -> "\nflags: " ++ str ++ ";")
                |> Maybe.withDefault ""

        content =
            interpolate """export function init(options: {
      node?: HTMLElement | null;{0}
    }): Elm.{1}.App;""" [ flagsStr, name ]
    in
    Writer { format = always content, children = [] }


indented : Int -> String -> String
indented amount code =
    code
        |> String.split "\n"
        |> List.map (\line -> indentation amount ++ line)
        |> String.join "\n"


indentation : Int -> String
indentation n =
    if n == 0 then
        ""

    else
        "  " ++ indentation (n - 1)
