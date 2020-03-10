module Util.List exposing (findMap)

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
