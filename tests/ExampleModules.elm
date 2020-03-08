module ExampleModules exposing (..)


counter =
    """
port module Counter exposing (main)

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
        , subscriptions = always Sub.none
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

port alert : String -> Cmd msg
"""


parsingFailure =
    """
module BadSadCode exposing (..)

main = type 3
"""


missingModuleDefinition =
    """import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


main : Program () String msg
main =
    Browser.sandbox { init = "World", update = update, view = view }


type alias Model =
    String


update : msg -> Model -> Model
update _ model =
    model


view name =
    div [] [ div [] [ text <| "Hello " ++ name ++ "!" ] ]
"""


missingMainFunction =
    """
module NoMain exposing (..)

five = 12
"""


missingMainSignature =
    """
module NoMainSig exposing (main)

main =
  Browser.sandbox { init = 0, update = update, view = div [] [] }

update : msg -> Model -> Model
update _ model =
    model
"""


nestedMainModuleUnsupported =
    """
module Nested.Main.Module exposing (main)

main : Program () Int msg
main =
  Browser.sandbox { init = 0, update = update, view = div [] [] }

update : msg -> Model -> Model
update _ model =
    model
"""
