module TypeScript.TSDoc exposing (TSDoc, docBody, docComment, fromElm, toString)

import Elm.ElmDoc as ElmDoc exposing (ElmDoc)


{-| Opaque type for a documentation comment in TypeScript
-}
type TSDoc
    = TSDoc String


{-| Make a doc comment from a string.
-}
docComment : String -> TSDoc
docComment body =
    TSDoc body


{-| Get to body of the doc comment.
-}
docBody : TSDoc -> String
docBody (TSDoc body) =
    body


{-| Make a TSDoc comment out of an ElmDoc comment.
-}
fromElm : ElmDoc -> TSDoc
fromElm elmDoc =
    elmDoc
        |> ElmDoc.docBody
        |> TSDoc


{-| Return the body of the comment, surrounded by TypeScript doc comment
syntax.
-}
toString : TSDoc -> String
toString (TSDoc body) =
    "/** " ++ body ++ " */"
