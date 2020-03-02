module Util.List exposing (filterMap, findMap)

import List


{-| Return the first `Just` value produced by `mapFn`, or `Nothing` if all
results are `Nothing`.
-}
findMap : (a -> Maybe b) -> List a -> Maybe b
findMap mapFn lst =
    List.foldl
        (\a found ->
            case found of
                Nothing ->
                    mapFn a

                Just _ ->
                    found
        )
        Nothing
        lst


{-| Returns a list of all `Just` values produced by `mapFn`.
-}
filterMap : (a -> Maybe b) -> List a -> List b
filterMap mapFn lst =
    List.foldr
        (\a acc ->
            case mapFn a of
                Just b ->
                    b :: acc

                Nothing ->
                    acc
        )
        []
        lst
