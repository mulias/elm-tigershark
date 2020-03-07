module Util.Composition exposing (applyIf)


applyIf : (a -> Bool) -> (a -> a) -> a -> a
applyIf predicate fn a =
    if predicate a then
        fn a

    else
        a
