module MainTest exposing (..)

import Elm.Interop as Interop
import Elm.ProgramInterface as ProgramInterface
import Elm.Project as Project exposing (FindBy(..))
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
                            [ { sourceDirectory = "src"
                              , filePath = "Double/Nested/Counter.elm"
                              , contents = counterIn
                              }
                            ]

                    result =
                        Project.readFileWith (FilePath "Double/Nested/Counter.elm") project
                            |> Result.andThen ProgramInterface.extract
                            |> Result.map (ProgramInterface.addImportedPorts project)
                            |> Result.andThen (Interop.program project)
                            |> Result.map ProgramDeclaration.assemble
                            |> Result.map List.singleton
                            |> Result.map DeclarationFile.write
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
port alert : String -> Cmd msg
"""


counterOut =
    """// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for using Elm programs in TypeScript

declare module '*.elm' {
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
  }
}
"""
