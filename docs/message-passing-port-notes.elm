port module Main exposing (Direction(..), Message(..))

import Json.Decode as JD
import Json.Encode as JE



{- Given the types -}


type Direction
    = North
    | South
    | East
    | West


type Message
    = Foo { fieldA : String, fieldB : Int }
    | Bar { x : Bool, y : Direction }


{-| @elm-tigershark use Message

We annotate the port with the Elm type which will be sent through the port.

-}
port sendMessage : JE.Value -> Cmd msg



{- This generates corresponding TypeScript types

      type Direction = "Noth" | "South" | "East" | "West"

      type Message =
          | { kind: "Foo"; fieldA: string; fieldB: number }
          | { kind: "Bar"; x: boolean; y: Direction }


   And also creates encoder/decoder pairs:
-}


decodeDirection : JD.Decoder Direction
decodeDirection =
    let
        toDirection string =
            case string of
                "East" ->
                    JD.succeed East

                "North" ->
                    JD.succeed North

                "South" ->
                    JD.succeed South

                "West" ->
                    JD.succeed West

                _ ->
                    JD.fail ("Invalid decoder value for Direction: " ++ string)
    in
    JD.string |> JD.andThen toDirection


encodeDirection : Direction -> JE.Value
encodeDirection direction =
    case direction of
        East ->
            JE.string "East"

        North ->
            JE.string "North"

        South ->
            JE.string "South"

        West ->
            JE.string "West"


decodeMessage : JD.Decoder Message
decodeMessage =
    let
        toMessageVarient string =
            case string of
                "Foo" ->
                    JD.map2
                        (\fieldA fieldB ->
                            Foo
                                { fieldA = fieldA
                                , fieldB = fieldB
                                }
                        )
                        (JD.field "fieldA" JD.string)
                        (JD.field "fieldB" JD.int)

                "Bar" ->
                    JD.map2
                        (\x y ->
                            Bar
                                { x = x
                                , y = y
                                }
                        )
                        (JD.field "x" JD.bool)
                        (JD.field "y" decodeDirection)

                _ ->
                    JD.fail ("Invalid decoder value for Message varient: " ++ string)
    in
    JD.field "kind" JD.string
        |> JD.andThen toMessageVarient


encodeMessage : Message -> JE.Value
encodeMessage message =
    case message of
        Foo { fieldA, fieldB } ->
            JE.object
                [ ( "kind", JE.string "Foo" )
                , ( "fieldA", JE.string fieldA )
                , ( "fieldB", JE.int fieldB )
                ]

        Bar { x, y } ->
            JE.object
                [ ( "kind", JE.string "Bar" )
                , ( "x", JE.bool x )
                , ( "y", encodeDirection y )
                ]
