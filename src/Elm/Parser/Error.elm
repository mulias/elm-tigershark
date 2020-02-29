module Elm.Parser.Error exposing (errorMessage)

import Elm.Parser as Parser
import Parser exposing (DeadEnd, Problem(..))


errorMessage : List DeadEnd -> String
errorMessage deadEnds =
    if List.any isMissingModuleStatement deadEnds then
        "No module name found"

    else
        "failed to parse module"


isMissingModuleStatement : DeadEnd -> Bool
isMissingModuleStatement deadEnd =
    List.member deadEnd.problem [ Expecting "module", Expecting "port", Expecting "effect" ]
