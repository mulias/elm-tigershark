module Util.String exposing (firstToLower, indented)


firstToLower : String -> String
firstToLower string =
    case String.uncons string of
        Just ( char, rest ) ->
            String.cons (Char.toLower char) rest

        Nothing ->
            ""


{-| Indent every line in a multiline block the same amount.
-}
indented : Int -> String -> String
indented amount code =
    let
        indentation =
            String.pad amount ' ' ""
    in
    code
        |> String.split "\n"
        |> List.map (\line -> indentation ++ line)
        |> String.join "\n"
