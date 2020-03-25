port module Main exposing (Direction(..), Message(..))

{-| Here's a code sketch inspired by <https://discourse.elm-lang.org/t/generating-type-safe-ports-from-custom-types/1841>
In addition to the primitive types which can be auto-converted through ports
and flags, there are two kinds of types which are conceptually comparable
between Elm and TS, but require conversion via encoder/decoder pairs.

The first kind of type is an "enum" type, created in Elm as a custom type where
each variant takes no type arguments, and created in TS as a union of string
literals.

The second kind of type is a "labeled record", created in Elm as a custom type
where each variant takes a record, and created in TS as a discriminated union.

It should be possible to facilitate this kind of higher level type interop by
generating the TS types for qualifying Elm types, and also generating the codec
functions to pass the types back and forth.

Open questions:

  - Where do the generated Elm codecs go
  - Do the types really need an `@elm-tigershark-type` annotation?
  - Do annotations stay in the doc comments added to the TS declarations
  - How should types be scoped?

-}

import Json.Decode as JD
import Json.Encode as JE


{-| Add the annotation

@elm-tigershark-type

in a doc comment to indicate that code should be generated to make this type
interoperable.

-}
type Direction
    = North
    | South
    | East
    | West


{-| @elm-tigershark-type
-}
type Message
    = Foo { fieldA : String, fieldB : Int }
    | Bar { x : Bool, y : Direction }


{-| Indicate what type a flags json value will decode to with

@elm-tigershark-flags-using Direction

-}
main : Program JD.Value model msg
main =
    Debug.todo "write main"


{-| Indicate what type a port json value will encode or decode to with

@elm-tigershark-port-using Message

-}
port sendMessage : JE.Value -> Cmd msg



{- This generates corresponding TypeScript types, and sets the type of the
   ports and flags appropriately

   declare module "*.elm" {
     export namespace Elm {
       namespace Main {

         type Direction = "Noth" | "South" | "East" | "West"

         type Message =
           | { kind: "Foo"; fieldA: string; fieldB: number }
           | { kind: "Bar"; x: boolean; y: Direction }

         export interface App {
           ports: {
             sendMessage: {
               subscribe(callback: (data: Message) => void): void;
             };
           };
           export function init(options: {
             node?: HTMLElement | null;
             flags: Direction;
           }): Elm.Main.App;
         }
       }
     }
   }

   And also creates Elm encoder/decoder pairs:
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
