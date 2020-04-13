module MainTest exposing (..)

import Elm.Interop as Interop
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project
import ExampleModules
import Expect
import Test exposing (..)
import TypeScript.DeclarationFile as DeclarationFile
import TypeScript.ProgramDeclaration as ProgramDeclaration


suite : Test
suite =
    describe "The Main module"
        [ test "Converts Elm to Typescript" <|
            \_ ->
                let
                    expected =
                        Ok counterOut

                    project =
                        Project.init
                            [ { sourceDirectory = [ "src" ]
                              , modulePath = ( [ "Double", "Nested" ], "Counter" )
                              , contents = Just counterIn
                              }
                            ]

                    result =
                        Project.readFile ( [ "Double", "Nested" ], "Counter" ) project
                            |> Result.andThen ProgramInterface.fromFile
                            |> Result.andThen (ProgramInterface.addImportedPorts project)
                            |> Result.andThen (Interop.fromProgramInterface project)
                            |> Result.map ProgramDeclaration.fromInterop
                            |> Result.map List.singleton
                            |> Result.map (DeclarationFile.write { declareInModule = Nothing })
                in
                Expect.equal expected result
        ]


counterIn =
    """port module Double.Nested.Counter exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)

type Msg = Increment | Decrement

type alias Flags = { startingNum : Int }

type alias AlertMessage = String

{-| Counter program. `startingNum` sets the initial count.
-}
main : Program Flags Int Msg
main { startingNum } =
    Browser.element
        { init = startingNum
        , update = update
        , view = view
        , subscriptions = always (incrementFromJS Increment)
        }


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
port alert : AlertMessage -> Cmd msg
"""


counterOut =
    """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for using Elm programs in TypeScript

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
        }): Elm.Double.Nested.Counter.App;
      }
    }
  }
}
"""
