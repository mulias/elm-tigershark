module Util.List exposing (assocFind, findMap, findMapResult, zip)

import List


assocFind : comparable -> List ( comparable, v ) -> Maybe v
assocFind key assocList =
    assocList
        |> findMap
            (\( k, v ) ->
                if k == key then
                    Just v

                else
                    Nothing
            )


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


{-| Return the first `Ok` value produced by `mapFn`, or the last `Err` if all
results are errors. The `emptyListError` argument is returned if the input list
is empty.
-}
findMapResult : (a -> Result x b) -> x -> List a -> Result x b
findMapResult mapFn emptyListError lst =
    List.foldl
        (\a found ->
            case found of
                Err _ ->
                    mapFn a

                Ok _ ->
                    found
        )
        (Err emptyListError)
        lst


zip : List a -> List b -> List ( a, b )
zip a b =
    List.map2 Tuple.pair a b
