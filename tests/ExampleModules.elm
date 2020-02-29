module ExampleModules exposing (..)


counter : String
counter =
    """module Counter exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)

main =
  Browser.sandbox { init = 0, update = update, view = view }

type Msg = Increment | Decrement

update msg model =
  case msg of
    Increment ->
      model + 1

    Decrement ->
      model - 1

view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (String.fromInt model) ]
    , button [ onClick Increment ] [ text "+" ]
    ]"""


noModuleStatement : String
noModuleStatement =
    """import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


main =
    Browser.sandbox { init = "World", update = update, view = view }


type alias Model =
    String


update : msg -> Model -> Model
update _ model =
    model


view name =
    div [] [ div [] [ text <| "Hello " ++ name ++ "!" ] ]"""
