module Util.Parser exposing (isMissingModuleDefinitionError)

{-| Helpers for parsing elm files with `elm-syntax`.
-}

import Parser exposing (DeadEnd, Problem(..))


{-| While `elm make` allows for modules without a module definition in
some cases, `elm-syntax` fails to parse in this situation. It's worth
calling out this specific case, since most other parsing errors will
also have an `elm-make` error with error message.
-}
isMissingModuleDefinitionError : List DeadEnd -> Bool
isMissingModuleDefinitionError deadEnds =
    List.any
        (\{ problem } ->
            List.member problem [ Expecting "module", Expecting "port", Expecting "effect" ]
        )
        deadEnds
