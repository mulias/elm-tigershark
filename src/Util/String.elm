module Util.String exposing (firstToLower, indented)


firstToLower : String -> String
firstToLower string =
    case String.uncons string of
        Just ( char, rest ) ->
            String.cons (Char.toLower char) rest

        Nothing ->
            ""


{-| Indent every line in a multiline block the same amount. The indentation is
in multiples of 2, so `amount` or 1 indents 2 spaces, `amount` 2 indents 4
spaces, etc.
-}
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
