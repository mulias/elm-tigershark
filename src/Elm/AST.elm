module Elm.AST exposing (..)

{-| AST types here are mirrors of `elm-syntax` AST types, but with the wrapping
Nodes stripped out. The data provided by `elm-syntax` uses Nodes to annotate
file positions. This is useful for cases such as error reporting or
re-constructing files, but for generating TS types we don't need it.
-}

import Elm.Syntax.Exposing as Exposing exposing (Exposing, TopLevelExpose)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Signature exposing (Signature)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))


type TypeAnnotationAST
    = GenericTypeAST String
    | TypedAST ( ModuleName, String ) (List TypeAnnotationAST)
    | UnitAST
    | TupledAST (List TypeAnnotationAST)
    | RecordAST RecordDefinitionAST
    | GenericRecordAST String RecordDefinitionAST
    | FunctionTypeAnnotationAST TypeAnnotationAST TypeAnnotationAST


type alias RecordDefinitionAST =
    List RecordFieldAST


type alias RecordFieldAST =
    ( String, TypeAnnotationAST )


type alias SignatureAST =
    { name : String, typeAnnotation : TypeAnnotationAST }


type ExposingAST
    = All
    | Explicit (List String)


type alias ImportAST =
    { moduleName : List String
    , moduleAlias : Maybe (List String)
    , exposingList : Maybe ExposingAST
    }


type alias TypeAliasAST =
    { documentation : Maybe String
    , name : String
    , generics : List String
    , typeAnnotation : TypeAnnotationAST
    }


toTypeAnnotationAST : TypeAnnotation -> TypeAnnotationAST
toTypeAnnotationAST ta =
    case ta of
        GenericType s ->
            GenericTypeAST s

        Typed tupleNode taNodes ->
            TypedAST (Node.value tupleNode) (List.map (Node.value >> toTypeAnnotationAST) taNodes)

        Unit ->
            UnitAST

        Tupled taNodes ->
            TupledAST (List.map (Node.value >> toTypeAnnotationAST) taNodes)

        Record rfNodes ->
            RecordAST (List.map (Node.value >> toRecordFieldAST) rfNodes)

        GenericRecord s rfNodes ->
            GenericRecordAST (Node.value s) (List.map (Node.value >> toRecordFieldAST) (Node.value rfNodes))

        FunctionTypeAnnotation taNode1 taNode2 ->
            FunctionTypeAnnotationAST (toTypeAnnotationAST (Node.value taNode1)) (toTypeAnnotationAST (Node.value taNode2))


toRecordFieldAST : RecordField -> RecordFieldAST
toRecordFieldAST ( sNode, taNode ) =
    ( Node.value sNode, toTypeAnnotationAST (Node.value taNode) )


toSignatureAST : Signature -> SignatureAST
toSignatureAST { name, typeAnnotation } =
    { name = Node.value name
    , typeAnnotation = toTypeAnnotationAST (Node.value typeAnnotation)
    }


toExposingAST : Exposing -> ExposingAST
toExposingAST exp =
    case exp of
        Exposing.All _ ->
            All

        Exposing.Explicit list ->
            list
                |> List.map (Node.value >> toTopLevelExposeAST)
                |> Explicit


toTopLevelExposeAST : TopLevelExpose -> String
toTopLevelExposeAST tle =
    case tle of
        Exposing.InfixExpose name ->
            name

        Exposing.FunctionExpose name ->
            name

        Exposing.TypeOrAliasExpose name ->
            name

        Exposing.TypeExpose { name } ->
            name


toImportAST : Import -> ImportAST
toImportAST { moduleName, moduleAlias, exposingList } =
    { moduleName = Node.value moduleName
    , moduleAlias = Maybe.map Node.value moduleAlias
    , exposingList = Maybe.map (Node.value >> toExposingAST) exposingList
    }


toTypeAliasAST : TypeAlias -> TypeAliasAST
toTypeAliasAST { documentation, name, generics, typeAnnotation } =
    { documentation = Maybe.map Node.value documentation
    , name = Node.value name
    , generics = List.map Node.value generics
    , typeAnnotation = typeAnnotation |> Node.value |> toTypeAnnotationAST
    }
