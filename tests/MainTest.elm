module MainTest exposing (..)

import Elm.ModuleCache as ModuleCache
import Elm.ProgramInterface as ProgramInterface
import ExampleModules
import Expect
import Test exposing (..)
import TypeScript.DeclarationFile as DeclarationFile
import TypeScript.Interop exposing (toProgramDeclaration)


suite : Test
suite =
    describe "The Main module"
        [ test "Converts Elm to Typescript" <|
            \_ ->
                let
                    expected =
                        Ok counterOut

                    result =
                        ModuleCache.fromList [ ( "Counter", counterIn ) ]
                            |> ModuleCache.readModule "Counter"
                            |> Result.andThen (Tuple.first >> ProgramInterface.extract)
                            |> Result.andThen toProgramDeclaration
                            |> Result.map (\declaration -> DeclarationFile.write [ declaration ])
                in
                Expect.equal expected result
        ]


counterIn =
    """port module Double.Nested.Counter exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)

{-| Counter program. `startingNum` sets the initial count.
-}
main : Program { startingNum : Int } Int Msg
main { startingNum } =
    Browser.element
        { init = startingNum
        , update = update
        , view = view
        , subscriptions = always (incrementFromJS Increment)
        }

type Msg = Increment | Decrement

update msg model =
  case msg of
    Increment ->
      (model + 1, alert "up")

    Decrement ->
      (model - 1, alert "down")

view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (String.fromInt model) ]
    , button [ onClick Increment ] [ text "+" ]
    ]

port incrementFromJS : (() -> msg) -> Sub msg
port alert : String -> Cmd msg"""


counterOut =
    """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for Elm ports

export namespace Elm {
  namespace Double {
    namespace Nested {
      /** Counter program. `startingNum` sets the initial count. */
      namespace Counter {
        export interface App {
          ports: {
            incrementFromJS: {
              send(data: null): void;
            };
            alert: {
              subscribe(callback: (data: string) => void): void;
            };
          };
        }
        export function init(options: {
          node?: HTMLElement | null;
          flags: {startingNum: number};
        }): Elm.Counter.App;
      }
    }
  }
}"""
