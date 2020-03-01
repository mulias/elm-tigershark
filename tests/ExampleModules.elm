module ExampleModules exposing (..)


counter =
    """
module Counter exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)

main : Program () Int Msg
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
    ]
"""


parsingFailure =
    """
module BadSadCode exposing (..)

main = type 3"""


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
