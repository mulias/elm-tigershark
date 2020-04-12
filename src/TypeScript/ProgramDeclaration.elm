module TypeScript.ProgramDeclaration exposing (ProgramDeclaration, fromInterop)

import Elm.AST exposing (SignatureAST, TypeAnnotationAST(..))
import Elm.Interop exposing (Interop(..), PortInterop(..), ProgramInterop)
import Elm.PortModule as PortModule
import Elm.ProgramInterface exposing (ProgramInterface)
import Result.Extra
import TypeScript.TSDoc as TSDoc
import TypeScript.TypeString exposing (InteropDirection(..), TypeString, toTypeString)


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
    , flags : TypeString
    , ports : List PortFunction
    }


{-| Convert the interoperable representation of an Elm program into the strings
needed to write a TypeScript declaration file.
-}
fromInterop : ProgramInterop -> ProgramDeclaration
fromInterop { moduleParents, moduleName, docs, flags, ports } =
    { moduleParents = moduleParents
    , moduleName = moduleName
    , docs = Maybe.map (TSDoc.docComment >> TSDoc.toString) docs
    , flags = flagsString flags
    , ports = List.map portString ports
    }


{-| Returns a `TypeString` for the flags passed to Elm.
-}
flagsString : Interop -> TypeString
flagsString interop =
    toTypeString Inbound interop


{-| Returns the name of the port and the `TypeString` function declaration for
either sending data to an inbound port or subscribing to data from an outbound
port.
-}
portString : PortInterop -> PortFunction
portString portInterop =
    case portInterop of
        InboundPort { name, inType } ->
            { name = name
            , body = "send(data: " ++ toTypeString Inbound inType ++ "): void"
            }

        OutboundPort { name, outType } ->
            { name = name
            , body = "subscribe(callback: (data: " ++ toTypeString Outbound outType ++ ") => void): void"
            }
