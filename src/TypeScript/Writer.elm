module TypeScript.Writer exposing
    ( Writer
    , autoGeneratedFileWarning
    , declareModule
    , file
    , initFn
    , interface
    , lines
    , namespace
    , newline
    , ports
    , toString
    )

{-| Templating system for building TypeScript declaration files. A Writer
encapsulates the layout rules for a block of text, end defines how nested child
Writers are composed.
-}

import String.Interpolate exposing (interpolate)


{-| Opaque type. Writers define structure in plain text, similar to how Elm's
HTML library defines structure for webpages.
-}
type Writer
    = Writer { format : List String -> String, children : List Writer }


{-| Build a string, using the Writer as a template.
-}
toString : Writer -> String
toString (Writer { format, children }) =
    children
        |> List.map toString
        |> format


{-| Writer which concats all children.
-}
file : List Writer -> Writer
file children =
    let
        format contents =
            contents |> String.join "" |> String.trimRight |> (\s -> s ++ "\n")
    in
    Writer { format = format, children = children }


{-| Writer which concats each child on a new line.
-}
lines : List Writer -> Writer
lines children =
    Writer { format = String.join "\n", children = children }


{-| Writer which writes a newline character.
-}
newline : Writer
newline =
    Writer { format = always "\n", children = [] }


{-| Writer for a comment warning that the file is auto-generated.
-}
autoGeneratedFileWarning : Writer
autoGeneratedFileWarning =
    let
        content =
            """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for using Elm programs in TypeScript
"""
    in
    Writer { format = always content, children = [] }


declareModule : String -> List Writer -> Writer
declareModule name children =
    let
        format contents =
            interpolate "declare module {0} {\n{1}\n}"
                [ name, indented 1 (String.join "\n" contents) ]
    in
    Writer
        { format = format, children = children }


{-| Writer which wraps `children` in a namespace declaration. For example:

    ```
    /** A doc comment */
    export namespace Foo {
        // children
    }
    ```

-}
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


{-| Writer which wraps `children` in an interface declaration. For example:

    ```
    export interface Bar {
      // children
    }
    ```

-}
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


{-| Writer for a list of port declarations. For example:

    ```
    ports: {
      portFoo: {
        send(data: string): void;
      }
    }
    ```

When the ports list is empty, an empty object is used:

    ```
    ports: {}
    ```

-}
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


{-| Writer for individual ports inside the ports object.
-}
portDeclaration : { name : String, body : String } -> Writer
portDeclaration { name, body } =
    let
        content =
            interpolate "{0}: {\n{1};\n};" [ name, indented 1 body ]
    in
    Writer { format = always content, children = [] }


{-| Writer for the init function used to mount Elm 0.19 programs. The
`moduleName` is needed for the namespaced function return type, and the flags
are used as the second argument to the function, if the program accepts flags.
-}
initFn : { moduleName : String, flags : Maybe String } -> Writer
initFn { moduleName, flags } =
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
            interpolate template [ nextLine, indented 1 flagsStr, moduleName ]
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
