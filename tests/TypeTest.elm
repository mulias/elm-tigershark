module TypeTest exposing (..)

import Elm.AST exposing (TypeAnnotationAST(..))
import Elm.Project as Project
import Elm.Type as Type
import Expect
import Main.Error as Error exposing (Error(..))
import Test exposing (..)


moduleFoo =
    """
module Foo exposing (Foo)

import Bar exposing (Bar)
import Json.Decoder

type alias Foo a = Bar a
"""


moduleBar =
    """
module Bar exposing (Bar)

import Baz

type alias Bar b = Baz.Baz b
"""


moduleBaz =
    """
module Baz exposing (..)

type alias Baz c = { x : List c }
"""


moduleMiscTypes =
    """
module MiscTypes exposing (..)

import Json.Decode as JD exposing (Value)

type alias Id i = i
type alias DropFirst a b = b

type alias GenericRecord a = { a | foo : Int }

type alias RecordWithGenerics a b = { x : a, y : DropFirst a b }

type alias TupleWithGenerics x y = (List x, List y)
"""


project =
    Project.init
        [ { sourceDirectory = [ "src" ], modulePath = ( [], "Foo" ), contents = Just moduleFoo }
        , { sourceDirectory = [ "src" ], modulePath = ( [], "Bar" ), contents = Just moduleBar }
        , { sourceDirectory = [ "src" ], modulePath = ( [], "Baz" ), contents = Just moduleBaz }
        , { sourceDirectory = [ "src" ], modulePath = ( [], "MiscTypes" ), contents = Just moduleMiscTypes }
        ]


suite : Test
suite =
    describe "Type.dealiasAndNormalize"
        [ describe "Replaces a type annotation with an alias definition or import"
            [ test "Substitute once, with local type" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "Foo" ]
                                , typeAnnotation = TypedAST ( [], "Bar" ) [ UnitAST ]
                                }

                        result =
                            { moduleContext = [ "Foo" ]
                            , typeAnnotation = TypedAST ( [], "Foo" ) [ UnitAST ]
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            , test "Substitute twice, with imported type" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "Bar" ]
                                , typeAnnotation = TypedAST ( [ "Baz" ], "Baz" ) [ UnitAST ]
                                }

                        result =
                            { moduleContext = [ "Foo" ]
                            , typeAnnotation = TypedAST ( [], "Foo" ) [ UnitAST ]
                            }
                                |> Type.dealiasAndNormalize project
                                |> Result.andThen (Type.dealiasAndNormalize project)
                    in
                    Expect.equal expected result
            , test "Substitute three times, finding a primitive type" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "Baz" ]
                                , typeAnnotation = RecordAST [ ( "x", TypedAST ( [], "List" ) [ UnitAST ] ) ]
                                }

                        result =
                            { moduleContext = [ "Foo" ]
                            , typeAnnotation = TypedAST ( [], "Foo" ) [ UnitAST ]
                            }
                                |> Type.dealiasAndNormalize project
                                |> Result.andThen (Type.dealiasAndNormalize project)
                                |> Result.andThen (Type.dealiasAndNormalize project)
                    in
                    Expect.equal expected result
            ]
        , describe "Fails when the type does not have an alias"
            [ test "Attempt to substitute after a primitive type has been found" <|
                \_ ->
                    let
                        expected =
                            Err (Fatal Error.SubstituteTypeNotFound)

                        result =
                            { moduleContext = [ "Foo" ]
                            , typeAnnotation = TypedAST ( [], "Foo" ) [ UnitAST ]
                            }
                                |> Type.dealiasAndNormalize project
                                |> Result.andThen (Type.dealiasAndNormalize project)
                                |> Result.andThen (Type.dealiasAndNormalize project)
                                |> Result.andThen (Type.dealiasAndNormalize project)
                    in
                    Expect.equal expected result
            , test "Bad type or external library type alias" <|
                \_ ->
                    let
                        expected =
                            Err (Fatal Error.AliasTypeNotFound)

                        result =
                            { moduleContext = [ "Baz" ]
                            , typeAnnotation = TypedAST ( [], "Bing" ) []
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            ]
        , describe "Normalizes Json Value types"
            [ test "Qualified Json.Decode.Value" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "Json", "Decode" ]
                                , typeAnnotation = TypedAST ( [ "Json", "Decode" ], "Value" ) []
                                }

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation = TypedAST ( [ "Json", "Decode" ], "Value" ) []
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            , test "Module alias JD.Value" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "Json", "Decode" ]
                                , typeAnnotation = TypedAST ( [ "Json", "Decode" ], "Value" ) []
                                }

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation = TypedAST ( [ "JD" ], "Value" ) []
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            , test "Unqualified Value" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "Json", "Decode" ]
                                , typeAnnotation = TypedAST ( [ "Json", "Decode" ], "Value" ) []
                                }

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation = TypedAST ( [], "Value" ) []
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            , test "Fails when Json module is not imported" <|
                \_ ->
                    let
                        expected =
                            Err (Fatal Error.AliasTypeNotFound)

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation = TypedAST ( [ "Json", "Encode" ], "Value" ) []
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            ]
        , describe "Substitute type arguments for generic types"
            [ test "Use type argument as type" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "MiscTypes" ]
                                , typeAnnotation = TypedAST ( [], "List" ) [ TypedAST ( [], "String" ) [] ]
                                }

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation =
                                TypedAST ( [], "Id" ) [ TypedAST ( [], "List" ) [ TypedAST ( [], "String" ) [] ] ]
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            , test "Unused generic" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "MiscTypes" ]
                                , typeAnnotation = UnitAST
                                }

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation =
                                TypedAST ( [], "DropFirst" ) [ TypedAST ( [], "String" ) [], UnitAST ]
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            , test "Generic record" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "MiscTypes" ]
                                , typeAnnotation =
                                    RecordAST
                                        [ ( "foo", TypedAST ( [], "Int" ) [] )
                                        , ( "bar", UnitAST )
                                        ]
                                }

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation =
                                TypedAST ( [], "GenericRecord" )
                                    [ RecordAST
                                        [ ( "foo", TypedAST ( [], "Int" ) [] )
                                        , ( "bar", UnitAST )
                                        ]
                                    ]
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            , test "Record with generics" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "MiscTypes" ]
                                , typeAnnotation =
                                    RecordAST
                                        [ ( "x", TypedAST ( [], "String" ) [] )
                                        , ( "y", TypedAST ( [], "DropFirst" ) [ TypedAST ( [], "String" ) [], UnitAST ] )
                                        ]
                                }

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation =
                                TypedAST ( [], "RecordWithGenerics" ) [ TypedAST ( [], "String" ) [], UnitAST ]
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            , test "Tuple with generics" <|
                \_ ->
                    let
                        expected =
                            Ok
                                { moduleContext = [ "MiscTypes" ]
                                , typeAnnotation =
                                    TupledAST
                                        [ TypedAST ( [], "List" ) [ TypedAST ( [], "String" ) [] ]
                                        , TypedAST ( [], "List" ) [ UnitAST ]
                                        ]
                                }

                        result =
                            { moduleContext = [ "MiscTypes" ]
                            , typeAnnotation =
                                TypedAST ( [], "TupleWithGenerics" ) [ TypedAST ( [], "String" ) [], UnitAST ]
                            }
                                |> Type.dealiasAndNormalize project
                    in
                    Expect.equal expected result
            ]
        ]
