module Interop exposing (Interop(..))

{-| Convert from Elm type annotations to Typescript type strings, going through
an intermediary `Interop` type. This middle type representation is technically
unnecessary but the resulting code is cleaner than going from AST to string in
one step.
-}


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
    |  Unit              |  null        |  UnitType

-}
type Interop
    = BooleanType
    | NumberType
    | StringType
    | MaybeType Interop
    | ArrayType Interop
    | TupleType (List Interop)
    | RecordType (List ( String, Interop ))
    | JsonType
    | UnitType
