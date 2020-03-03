module Elm.Interop exposing (fromAST)

import Elm.AST exposing (SignatureAST, TypeAnnotationAST(..))
import Error exposing (Error)
import Interop exposing (Interop(..))
import Result.Extra


{-| Construct an Interop type from the given Elm AST. Returns an error if the
type can't be used for interop, although this error should not come up in
correctly typechecked Elm code.
-}
fromAST : TypeAnnotationAST -> Result Error Interop
fromAST typeAST =
    case typeAST of
        GenericTypeAST _ ->
            Err Error.UninteroperableType

        TypedAST ( [], "Bool" ) [] ->
            Ok BooleanType

        TypedAST ( [], "Int" ) [] ->
            Ok NumberType

        TypedAST ( [], "Float" ) [] ->
            Ok NumberType

        TypedAST ( [], "String" ) [] ->
            Ok StringType

        TypedAST ( [], "Maybe" ) [ typeArg ] ->
            Result.map MaybeType (fromAST typeArg)

        TypedAST ( [], "Array" ) [ typeArg ] ->
            Result.map ArrayType (fromAST typeArg)

        {- TODO: Check for Value in imports -}
        TypedAST ( [ "Json", "Decode" ], "Value" ) [] ->
            Ok JsonType

        TypedAST ( moduleName, typeStr ) typeArgs ->
            Err Error.AliasTypesNotSupported

        UnitAST ->
            Ok UnitType

        TupledAST tupleTypes ->
            tupleTypes
                |> List.map fromAST
                |> Result.Extra.combine
                |> Result.map TupleType

        RecordAST recordFields ->
            recordFields
                |> List.map
                    (\( propertyName, propType ) ->
                        fromAST propType |> Result.map (Tuple.pair propertyName)
                    )
                |> Result.Extra.combine
                |> Result.map RecordType

        GenericRecordAST _ _ ->
            Err Error.UninteroperableType

        FunctionTypeAnnotationAST _ _ ->
            Err Error.UninteroperableType
