module Elm.Interop exposing (Interop(..), PortInterop(..), ProgramInterop, fromProgramInterface)

{-| Convert from Elm type annotations to an `Interop` type, which represents
the values that can be safely transfered through flags and ports. We use a
`ProgramInterop` record as an intermediary step to convert from an Elm
`ProgramInterface` to a TypeScript `ProgramDeclaration`.
-}

import Elm.AST exposing (SignatureAST, TypeAnnotationAST(..))
import Elm.ElmDoc as ElmDoc
import Elm.ModulePath as ModulePath exposing (ModuleName, ModulePath)
import Elm.PortModule as PortModule exposing (Port, PortModule)
import Elm.ProgramInterface exposing (ProgramInterface)
import Elm.Project exposing (Project)
import Elm.Syntax.File exposing (File)
import Elm.Type as Type
import Error exposing (Error(..))
import Result.Extra


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


{-| Information about an Elm program, in a format that can be passed to the
TypeScript declaration file builder.
-}
type alias ProgramInterop =
    { moduleParents : List String
    , moduleName : String
    , docs : Maybe String
    , flags : Interop
    , ports : List PortInterop
    }


{-| For ports, in addition to the Interop type for the data passed through the
port, we need to know what callback function the port uses in JS (the port's
name) and if the port is for sending data to Elm (inbound) or from Elm
(outbound).
-}
type PortInterop
    = InboundPort { name : String, inType : Interop }
    | OutboundPort { name : String, outType : Interop }


{-| Given an Elm ProgramInterface, parse the types to produce the corresponding
ProgramInterop. Fails if either the flag types of port types can't be converted
to Interop equivalents.
-}
fromProgramInterface : Project -> ProgramInterface -> Result Error ProgramInterop
fromProgramInterface project programInterface =
    Result.map2
        (\flags ports ->
            { moduleParents = ModulePath.namespace programInterface.modulePath
            , moduleName = ModulePath.name programInterface.modulePath
            , docs = Maybe.map ElmDoc.docBody programInterface.docs
            , flags = flags
            , ports = ports
            }
        )
        (programFlags project programInterface)
        (programPorts project programInterface)


programFlags : Project -> ProgramInterface -> Result Error Interop
programFlags project { modulePath, flags } =
    fromAST project (ModulePath.toNamespace modulePath) flags


programPorts : Project -> ProgramInterface -> Result Error (List PortInterop)
programPorts project { modulePath, ports } =
    ports
        |> PortModule.withDefault []
        |> List.map (programPort project)
        |> Result.Extra.combine


programPort : Project -> Port -> Result Error PortInterop
programPort project { name, typeAnnotation, declaredInModule } =
    case typeAnnotation of
        FunctionTypeAnnotationAST (FunctionTypeAnnotationAST inTypeAST _) (TypedAST ( [], "Sub" ) [ GenericTypeAST _ ]) ->
            fromAST project declaredInModule inTypeAST
                |> Result.map (\inType -> InboundPort { name = name, inType = inType })
                |> Result.mapError (always (Fatal Error.InvalidPortSignature))

        FunctionTypeAnnotationAST outTypeAST (TypedAST ( [], "Cmd" ) [ GenericTypeAST _ ]) ->
            fromAST project declaredInModule outTypeAST
                |> Result.map (\outType -> OutboundPort { name = name, outType = outType })
                |> Result.mapError (always (Fatal Error.InvalidPortSignature))

        _ ->
            Err (Fatal Error.InvalidPortSignature)


{-| Given a type annotation, try to produce a corresponding Interop type. If
the type annotation does not immediately map to an Interop type, look for an
alias or normalized type which can be substituted in place of the type
annotation.
-}
fromAST : Project -> List ModuleName -> TypeAnnotationAST -> Result Error Interop
fromAST project moduleContext typeAST =
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
            Result.map MaybeType (fromAST project moduleContext typeArg)

        TypedAST ( [], "List" ) [ typeArg ] ->
            Result.map ArrayType (fromAST project moduleContext typeArg)

        TypedAST ( [], "Array" ) [ typeArg ] ->
            Result.map ArrayType (fromAST project moduleContext typeArg)

        TypedAST ( [ "Json", "Decode" ], "Value" ) [] ->
            Ok JsonType

        TypedAST ( [ "Json", "Encode" ], "Value" ) [] ->
            Ok JsonType

        TypedAST typeReference typeArgs ->
            Type.dealiasAndNormalize project
                { moduleContext = moduleContext
                , typeAnnotation = TypedAST typeReference typeArgs
                }
                |> Result.andThen
                    (\normalizedType ->
                        fromAST project normalizedType.moduleContext normalizedType.typeAnnotation
                    )

        UnitAST ->
            Ok UnitType

        TupledAST tupleTypes ->
            tupleTypes
                |> List.map (fromAST project moduleContext)
                |> Result.Extra.combine
                |> Result.map TupleType

        RecordAST recordFields ->
            recordFields
                |> List.map
                    (\( propertyName, propType ) ->
                        fromAST project moduleContext propType
                            |> Result.map (Tuple.pair propertyName)
                    )
                |> Result.Extra.combine
                |> Result.map RecordType

        ast ->
            Err (Fatal Error.UninteroperableType)
