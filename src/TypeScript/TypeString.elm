module TypeScript.TypeString exposing (InteropDirection(..), TypeString, toTypeString)

import Elm.Interop exposing (Interop(..))
import Error exposing (Error(..))
import Result.Extra


{-| A valid TypeScript type, encoded in a string.
-}
type alias TypeString =
    String


{-| Specifies if the type will be passed from TypeScript to Elm (Inbound), or
Elm to TypeScript (Outbound). The TypeString used to represent an Interop type
may change based off of this direction.
-}
type InteropDirection
    = Inbound
    | Outbound


{-| Create a TypeScript `TypeString` that corresponds to the given Interop
type. When the `direction` argument is `Inbound`, we know that data is flowing
from TypeScript to Elm. In this case we translate `JsonType` as a Typescript
`any`, since Elm will accept and validate any value. When `drection` is
`Outbound`, data is flowing from Elm to TypeScript. In this case we translate
`JsonType` as `unknown`, for similar reasons.
-}
toTypeString : InteropDirection -> Interop -> TypeString
toTypeString direction interop =
    case interop of
        BooleanType ->
            "boolean"

        NumberType ->
            "number"

        StringType ->
            "string"

        MaybeType interopArg ->
            toTypeString direction interopArg ++ " | null"

        ArrayType interopArg ->
            "Array<" ++ toTypeString direction interopArg ++ ">"

        TupleType interopArgs ->
            let
                body =
                    interopArgs
                        |> List.map (toTypeString direction)
                        |> String.join ", "
            in
            "[" ++ body ++ "]"

        RecordType pairs ->
            let
                body =
                    pairs
                        |> List.map (\( key, val ) -> key ++ ": " ++ toTypeString direction val)
                        |> String.join "; "
            in
            "{" ++ body ++ "}"

        JsonType ->
            case direction of
                Outbound ->
                    "unknown"

                Inbound ->
                    "any"

        UnitType ->
            "null"
