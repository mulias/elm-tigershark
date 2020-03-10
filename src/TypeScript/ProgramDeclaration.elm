module TypeScript.ProgramDeclaration exposing (ProgramDeclaration, assemble)

import Elm.AST exposing (SignatureAST, TypeAnnotationAST(..))
import Elm.Interop exposing (Interop(..), fromAST)
import Elm.PortModule as PortModule
import Elm.ProgramInterface exposing (ProgramInterface)
import Error exposing (Error)
import Result.Extra
import TypeScript.TSDoc as TSDoc
import TypeScript.TypeString exposing (TypeString, TypeStringFor(..), toTypeString)


{-| A "send" or "subscribe" function to interface with ports from TypeScript.
-}
type alias PortFunction =
    { name : String, body : TypeString }


{-| All of the formatted strings needed to build a declaration file. While
these parts of the declaration file are internally formatted, contextual
formatting such as indentation and ending semi-colons has not been applied.
-}
type alias ProgramDeclaration =
    { moduleParents : List String
    , moduleName : String
    , docs : Maybe String
    , flags : Maybe TypeString
    , ports : List PortFunction
    }


{-| Convert an Elm program interface to the strings needed to write a
TypeScript declaration file.
-}
assemble : ProgramInterface -> Result Error ProgramDeclaration
assemble p =
    Result.map2
        (\flagsStr portStrs ->
            { moduleParents = p.moduleParents
            , moduleName = p.moduleName
            , docs = Maybe.map (TSDoc.fromElm >> TSDoc.toString) p.docs
            , flags = flagsStr
            , ports = portStrs
            }
        )
        (flags p.flags)
        (p.ports
            |> PortModule.withDefault []
            |> List.map portFunction
            |> Result.Extra.combine
        )


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
                    Just (toTypeString Flags interop)
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
            Err Error.InvalidPortSignature


inboundPort : TypeAnnotationAST -> Result Error TypeString
inboundPort typeAST =
    typeAST
        |> fromAST
        |> Result.map (toTypeString InboundPort)
        |> Result.map
            (\dataType -> "send(data: " ++ dataType ++ "): void")


outboundPort : TypeAnnotationAST -> Result Error TypeString
outboundPort typeAST =
    typeAST
        |> fromAST
        |> Result.map (toTypeString OutboundPort)
        |> Result.map
            (\dataType -> "subscribe(callback: (data: " ++ dataType ++ ") => void): void")
