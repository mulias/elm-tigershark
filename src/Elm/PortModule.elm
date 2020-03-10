module Elm.PortModule exposing (PortModule(..), toMaybe, withDefault)

import Elm.AST exposing (SignatureAST)


type PortModule
    = NotPortModule
    | ModuleWithPorts (List SignatureAST)


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
