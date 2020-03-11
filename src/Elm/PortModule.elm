module Elm.PortModule exposing (PortModule(..), map, toMaybe, withDefault)

import Elm.AST exposing (SignatureAST)


type PortModule
    = NotPortModule
    | ModuleWithPorts (List SignatureAST)


map : (List SignatureAST -> List SignatureAST) -> PortModule -> PortModule
map mapFn portModule =
    case portModule of
        ModuleWithPorts ports ->
            ModuleWithPorts (mapFn ports)

        NotPortModule ->
            NotPortModule


toMaybe : PortModule -> Maybe (List SignatureAST)
toMaybe portsModule =
    case portsModule of
        ModuleWithPorts ports ->
            Just ports

        NotPortModule ->
            Nothing


withDefault : List SignatureAST -> PortModule -> List SignatureAST
withDefault default portsModule =
    portsModule |> toMaybe |> Maybe.withDefault default