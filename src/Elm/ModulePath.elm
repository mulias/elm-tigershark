module Elm.ModulePath exposing (ModuleName, ModulePath, child, fromList, parents, toList)

{-| -}


{-| The name of a module, such as "Foo" for the file "src/Foo.elm".
-}
type alias ModuleName =
    String


{-| The full path to reference a module, such as `(["A", "B"], "C")` for the
file "src/A/B/C.elm".
-}
type alias ModulePath =
    ( List ModuleName, ModuleName )


fromList : List ModuleName -> Maybe ModulePath
fromList moduleNames =
    case List.reverse moduleNames of
        [] ->
            Nothing

        [ childName ] ->
            Just ( [], childName )

        childName :: parentNames ->
            Just ( List.reverse parentNames, childName )


toList : ModulePath -> List ModuleName
toList ( parentNames, childName ) =
    List.append parentNames [ childName ]


parents : ModulePath -> List ModuleName
parents =
    Tuple.first


child : ModulePath -> ModuleName
child =
    Tuple.second
