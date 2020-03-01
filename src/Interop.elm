module Interop exposing (..)

import Dict exposing (Dict)


{-|

    |  Elm               |  TypeScript  |  TS Interop
    |--------------------+--------------+-----------------
    |  Bool              |  boolean     |  TSBoolean
    |  Int               |  number      |  TSNumber
    |  Float             |  number      |  TSNumber
    |  String            |  string      |  TSString
    |  Maybe a           |  A | null    |  TSTypeOrNull
    |  List a            |  Array<A>    |  TSArray
    |  Array a           |  Array<A>    |  TSArray
    |  (a, b)            |  [A, B]      |  TSTwoTuple
    |  (a, b, c)         |  [A, B, C]   |  TSThreeTuple
    |  record            |  record      |  TSRecord
    |  Json.Decode.Value |  any/unknown |  TSJson

-}
type Interop
    = BooleanType
    | NumberType
    | StringType
    | TypeOrNull Interop
    | ArrayType Interop
    | TwoTupleType Interop Interop
    | ThreeTupleType Interop Interop Interop
    | RecordType (Dict String Interop)
    | JsonType


{-| Intermediat state when converting from an AST to Interop types. The basic
types have been converted, but alias types may require much more work parsing
and searching import files.
-}
type InteropOrAliases
    = Interoperable Interop
    | Alias String
