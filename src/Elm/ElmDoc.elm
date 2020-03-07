module Elm.ElmDoc exposing (ElmDoc, docBody, docComment, fromAST, toString)

import String exposing (dropLeft, dropRight, endsWith, startsWith, trim)
import Util.Composition exposing (applyIf)


{-| Opaque type for a documentation comment in Elm
-}
type ElmDoc
    = ElmDoc String


{-| Make a doc comment from a string.
-}
docComment : String -> ElmDoc
docComment body =
    ElmDoc body


{-| Get to body of the doc comment.
-}
docBody : ElmDoc -> String
docBody (ElmDoc body) =
    body


{-| Make a doc comment from a string, stripping the surrounding comment
markers. This handles the doc comment strings found in `elm-syntax` ASTs.
-}
fromAST : String -> ElmDoc
fromAST string =
    string
        |> trim
        |> applyIf (startsWith "{-|") (dropLeft 3)
        |> applyIf (endsWith "-}") (dropRight 2)
        |> trim
        |> ElmDoc


{-| Return the body of the comment, surrounded by Elm doc comment syntax.
-}
toString : ElmDoc -> String
toString (ElmDoc body) =
    "{-| " ++ body ++ " -}"
