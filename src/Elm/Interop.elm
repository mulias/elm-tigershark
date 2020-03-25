module Elm.Interop exposing (Interop(..), PortInterop(..), ProgramInterop, program)

{-| Convert from Elm type annotations to an `Interop` type, which represents
the values that can be safely transfered through flags and ports. We use a
`ProgramInterop` record as an intermediary step to convert from an Elm
`ProgramInterface` to a TypeScript `ProgramDeclaration`.
-}

import Elm.AST exposing (SignatureAST, TypeAnnotationAST(..))
import Elm.ElmDoc as ElmDoc
import Elm.PortModule as PortModule exposing (Port, PortModule)
import Elm.ProgramInterface exposing (ProgramInterface)
import Elm.Project exposing (Project)
import Elm.Syntax.File exposing (File)
import Error exposing (Error)
import Result.Extra
import Util.Elm.Syntax.File exposing (fileModuleName)


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


type alias ProgramInterop =
    { moduleParents : List String
    , moduleName : String
    , docs : Maybe String
    , flags : Interop
    , ports : List PortInterop
    }


type PortInterop
    = InboundPort { name : String, inType : Interop }
    | OutboundPort { name : String, outType : Interop }


program : Project -> ProgramInterface -> Result Error ProgramInterop
program project programInterface =
    Result.map2
        (\flags ports ->
            { moduleParents = programInterface.moduleParents
            , moduleName = programInterface.moduleName
            , docs = Maybe.map ElmDoc.docBody programInterface.docs
            , flags = flags
            , ports = ports
            }
        )
        (programFlags project programInterface)
        (programPorts project programInterface)


programFlags : Project -> ProgramInterface -> Result Error Interop
programFlags project { flags } =
    case resolveInteroperable flags of
        Ok interop ->
            Ok interop

        Err unknownType ->
            Err Error.UninteroperableType


programPorts : Project -> ProgramInterface -> Result Error (List PortInterop)
programPorts project { ports } =
    ports
        |> PortModule.withDefault []
        |> List.map (programPort project)
        |> Result.Extra.combine


programPort : Project -> Port -> Result Error PortInterop
programPort project { name, typeAnnotation } =
    case typeAnnotation of
        FunctionTypeAnnotationAST (FunctionTypeAnnotationAST inTypeAST _) (TypedAST ( [], "Sub" ) [ GenericTypeAST _ ]) ->
            resolveInteroperable inTypeAST
                |> Result.map (\inType -> InboundPort { name = name, inType = inType })
                |> Result.mapError (always Error.InvalidPortSignature)

        FunctionTypeAnnotationAST outTypeAST (TypedAST ( [], "Cmd" ) [ GenericTypeAST _ ]) ->
            resolveInteroperable outTypeAST
                |> Result.map (\outType -> OutboundPort { name = name, outType = outType })
                |> Result.mapError (always Error.InvalidPortSignature)

        _ ->
            Err Error.InvalidPortSignature


{-| Given a type annotation, try to return the Interop type that it corresponds
to. If the annotation does not directly map to an Interop type, then return the
annotation as an error.
-}
resolveInteroperable : TypeAnnotationAST -> Result TypeAnnotationAST Interop
resolveInteroperable typeAST =
    case typeAST of
        TypedAST ( [], "Bool" ) [] ->
            Ok BooleanType

        TypedAST ( [], "Int" ) [] ->
            Ok NumberType

        TypedAST ( [], "Float" ) [] ->
            Ok NumberType

        TypedAST ( [], "String" ) [] ->
            Ok StringType

        TypedAST ( [], "Maybe" ) [ typeArg ] ->
            Result.map MaybeType (resolveInteroperable typeArg)

        TypedAST ( [], "List" ) [ typeArg ] ->
            Result.map ArrayType (resolveInteroperable typeArg)

        TypedAST ( [], "Array" ) [ typeArg ] ->
            Result.map ArrayType (resolveInteroperable typeArg)

        TypedAST ( [ "Json", "Decode" ], "Value" ) [] ->
            Ok JsonType

        TypedAST ( [ "Json", "Encode" ], "Value" ) [] ->
            Ok JsonType

        UnitAST ->
            Ok UnitType

        TupledAST tupleTypes ->
            tupleTypes
                |> List.map resolveInteroperable
                |> Result.Extra.combine
                |> Result.map TupleType

        RecordAST recordFields ->
            recordFields
                |> List.map
                    (\( propertyName, propType ) ->
                        resolveInteroperable propType |> Result.map (Tuple.pair propertyName)
                    )
                |> Result.Extra.combine
                |> Result.map RecordType

        ast ->
            Err ast
