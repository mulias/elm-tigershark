module TypeScript.Interop exposing (toDeclarationFile)

import Elm.AST exposing (SignatureAST, TypeAnnotationAST(..))
import Elm.Interop exposing (fromAST)
import Elm.ProgramInterface exposing (ElmDocs, ProgramInterface)
import Error exposing (Error)
import Interop exposing (Interop(..))
import List.Nonempty as NE
import Result.Extra
import TypeScript.DeclarationFile exposing (DeclarationFile, PortFunction, TSDocs, TypeString)


{-| Specifies the part of the TypeScript declaration file in which the type
string will be used. Here "outbound" means from Elm to TypeScript.
-}
type TypeStringFor
    = Flags
    | InboundPort
    | OutboundPort


{-| Convert an Elm program interface to the strings needed to write a
TypeScript declaration file.
-}
toDeclarationFile : ProgramInterface -> Result Error DeclarationFile
toDeclarationFile p =
    Result.map4 DeclarationFile
        (Ok (NE.head p.moduleName))
        (Ok (Maybe.map docComment p.docs))
        (flags p.flags)
        (p.ports
            |> List.map portFunction
            |> Result.Extra.combine
        )


{-| Convert from an Elm doc comment to a TypeScript doc comment.
-}
docComment : ElmDocs -> TSDocs
docComment comment =
    let
        body =
            comment
                |> String.trim
                |> String.dropLeft 3
                |> String.dropRight 2
                |> String.trim
    in
    "/** " ++ body ++ " */"


{-| Returns a TypeScript `TypeString` for the flags passed to Elm. The value
is `Nothing` when there are no flags to pass.
-}
flags : TypeAnnotationAST -> Result Error (Maybe TypeString)
flags typeAST =
    typeAST
        |> fromAST
        |> Result.map
            (\interop ->
                if interop == UnitType then
                    Nothing

                else
                    Just (toString Flags interop)
            )


{-| Returns the name of the port and the `TypeString` function declaration for
either sending data to an inbound port or subscribing to data from an outbound
port.
-}
portFunction : SignatureAST -> Result Error PortFunction
portFunction { name, typeAnnotation } =
    case typeAnnotation of
        FunctionTypeAnnotationAST (FunctionTypeAnnotationAST inType _) (TypedAST ( [], "Sub" ) [ GenericTypeAST "msg" ]) ->
            inboundPort inType
                |> Result.map (\body -> { name = name, body = body })

        FunctionTypeAnnotationAST outType (TypedAST ( [], "Cmd" ) [ GenericTypeAST "msg" ]) ->
            outboundPort outType
                |> Result.map (\body -> { name = name, body = body })

        _ ->
            Err Error.UnknownPortSignature


inboundPort : TypeAnnotationAST -> Result Error TypeString
inboundPort typeAST =
    typeAST
        |> fromAST
        |> Result.map (toString InboundPort)
        |> Result.map
            (\dataType -> "send(data: " ++ dataType ++ "): void")


outboundPort : TypeAnnotationAST -> Result Error TypeString
outboundPort typeAST =
    typeAST
        |> fromAST
        |> Result.map (toString OutboundPort)
        |> Result.map
            (\dataType -> "subscribe(callback: (data: " ++ dataType ++ ") => void): void")


{-| Create a TypeScript `TypeString` that corresponds to the given Interop type.
When the `target` argument is either `Flags` or `InboundPort`, we know that
data is flowing from TypeScript to Elm. In this case we translate `JsonType` as
a Typescript `any`, since Elm will accept and validate any value. When `target`
is `OutboundPort`, data is flowing from Elm to TypeScript. In this case we
translate `JsonType` as `unknown`, for similar reasons.
-}
toString : TypeStringFor -> Interop -> TypeString
toString target interop =
    case interop of
        BooleanType ->
            "boolean"

        NumberType ->
            "number"

        StringType ->
            "string"

        MaybeType interopArg ->
            toString target interopArg ++ " | null"

        ArrayType interopArg ->
            "Array<" ++ toString target interopArg ++ ">"

        TupleType interopArgs ->
            let
                body =
                    interopArgs
                        |> List.map (toString target)
                        |> String.join ", "
            in
            "[" ++ body ++ "]"

        RecordType pairs ->
            let
                body =
                    pairs
                        |> List.map (\( key, val ) -> key ++ ": " ++ toString target val)
                        |> String.join "; "
            in
            "{" ++ body ++ "}"

        JsonType ->
            if target == OutboundPort then
                "unknown"

            else
                "any"

        UnitType ->
            "null"
