module Elm.PortModule exposing (Port, PortModule(..), map, toMaybe, withDefault)

import Elm.AST exposing (TypeAnnotationAST)
import Elm.ModulePath exposing (ModuleNamespace)


type alias Port =
    { name : String
    , typeAnnotation : TypeAnnotationAST
    , declaredInModule : ModuleNamespace
    }


type PortModule
    = NotPortModule
    | ModuleWithPorts (List Port)


map : (List Port -> List Port) -> PortModule -> PortModule
map mapFn portModule =
    case portModule of
        ModuleWithPorts ports ->
            ModuleWithPorts (mapFn ports)

        NotPortModule ->
            NotPortModule


toMaybe : PortModule -> Maybe (List Port)
toMaybe portsModule =
    case portsModule of
        ModuleWithPorts ports ->
            Just ports

        NotPortModule ->
            Nothing


withDefault : List Port -> PortModule -> List Port
withDefault default portsModule =
    portsModule |> toMaybe |> Maybe.withDefault default
