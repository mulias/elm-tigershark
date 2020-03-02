module TypeScript.Writer exposing (file, initFn, interface, namespace, newline, ports, prefix, toString)

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
    Writer { format = String.join "", children = children }


newline : Writer
newline =
    Writer { format = always "\n", children = [] }


prefix : Writer
prefix =
    let
        content =
            """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for Elm ports
"""
    in
    Writer { format = always content, children = [] }


namespace : { docs : Maybe String, export : Bool, name : String } -> List Writer -> Writer
namespace { docs, export, name } children =
    let
        docStr =
            docs
                |> Maybe.map (\str -> str ++ "\n")
                |> Maybe.withDefault ""

        exportStr =
            if export then
                "export "

            else
                ""

        format contents =
            interpolate "{0}{1}namespace {2} {\n{3}\n}"
                [ docStr, exportStr, name, indented 1 (String.join "\n" contents) ]
    in
    Writer
        { format = format, children = children }


interface : { export : Bool, name : String } -> List Writer -> Writer
interface { export, name } children =
    let
        exportStr =
            if export then
                "export "

            else
                ""

        format contents =
            interpolate "{0}interface {1} {\n{2}\n}"
                [ exportStr, name, indented 1 (String.join "\n" contents) ]
    in
    Writer
        { format = format, children = children }


ports : List { name : String, body : String } -> Writer
ports portDefs =
    let
        format contents =
            interpolate "ports: {{0}{1}{2}};"
                (if List.isEmpty contents then
                    [ "", "", "" ]

                 else
                    [ "\n", indented 1 (String.join "\n" contents), "\n" ]
                )
    in
    Writer { format = format, children = List.map portDeclaration portDefs }


portDeclaration : { name : String, body : String } -> Writer
portDeclaration { name, body } =
    let
        content =
            interpolate "{0}: {\n{1};\n};" [ name, indented 1 body ]
    in
    Writer { format = always content, children = [] }


initFn : String -> Maybe String -> Writer
initFn name flags =
    let
        flagsStr =
            flags
                |> Maybe.map (\str -> "flags: " ++ str ++ ";")
                |> Maybe.withDefault ""

        nextLine =
            flags |> Maybe.map (always "\n") |> Maybe.withDefault ""

        template =
            """export function init(options: {
  node?: HTMLElement | null;{0}{1}
}): Elm.{2}.App;"""

        content =
            interpolate template [ nextLine, indented 1 flagsStr, name ]
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
