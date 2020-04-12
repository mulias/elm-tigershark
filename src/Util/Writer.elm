module Util.Writer exposing (Writer, file, lines, newline, toString, writer)

{-| A simple templating system. Writers define structure in plain text, similar
to how Elm's HTML library defines structure for webpages. A Writer encapsulates
the layout rules for a block of text, and defines how nested child Writers are
composed.
-}


{-| Opaque type for a Writer.
-}
type Writer
    = Writer { format : List String -> String, children : List Writer }


{-| Define a new Writer. When `toString` is called on a writer all `children`
are turned into strings recursively, and then the `format` function is applied
to concatenate the child strings together and add additional content or
formatting.
-}
writer : { format : List String -> String, children : List Writer } -> Writer
writer =
    Writer


{-| Build a string, using the Writer as a template.
-}
toString : Writer -> String
toString (Writer { format, children }) =
    children
        |> List.map toString
        |> format


{-| Writer which concatenates all children. Cleans up any trailing whitespace
and makes sure that the file ends with a newline.
-}
file : List Writer -> Writer
file children =
    let
        format contents =
            contents |> String.join "" |> String.trimRight |> (\s -> s ++ "\n")
    in
    writer { format = format, children = children }


{-| Writer which concats each child on a new line.
-}
lines : List Writer -> Writer
lines children =
    writer { format = String.join "\n", children = children }


{-| Writer which writes a newline character.
-}
newline : Writer
newline =
    writer { format = always "\n", children = [] }
