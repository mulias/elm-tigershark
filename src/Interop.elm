module Interop exposing (..)

import Dict exposing (Dict)


{-| The types that can be passed between Elm and TypeScript via flags and ports.

    |  Elm               |  TypeScript  |  Interop
    |--------------------+--------------+-----------------
    |  Bool              |  boolean     |  BooleanType
    |  Int               |  number      |  NumberType
    |  Float             |  number      |  NumberType
    |  String            |  string      |  StringType
    |  Maybe a           |  A | null    |  MaybeType
    |  List a            |  Array<A>    |  ArrayType
    |  Array a           |  Array<A>    |  ArrayType
    |  (a, b, c)         |  [A, B, C]   |  TupleType
    |  record            |  record      |  RecordType
    |  Json.Decode.Value |  any/unknown |  JsonType

-}
type Interop
    = BooleanType
    | NumberType
    | StringType
    | MaybeType Interop
    | ArrayType Interop
    | TupleType (List Interop)
    | RecordType (Dict String Interop)
    | JsonType


{-| Intermediate state when converting from an AST to Interop types. The basic
types have been converted, but alias types may require much more work parsing
and searching import files.
-}
type InteropOrAliases
    = Interoperable Interop
    | Alias String
