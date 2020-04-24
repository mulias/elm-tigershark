port module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Json.Encode as JE


type alias Model =
    { message : String }


type Msg
    = GotMessage String
    | SendAppData


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { message = "" }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotMessage message ->
            ( { model | message = message }, Cmd.none )

        SendAppData ->
            ( model, sendAppData <| encodeModel model )


view : Model -> Html Msg
view model =
    div [] [ text model.message ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    gotMessage GotMessage


encodeModel : Model -> JE.Value
encodeModel { message } =
    JE.object [ ( "message", JE.string message ) ]


port gotMessage : (String -> msg) -> Sub msg


port sendAppData : JE.Value -> Cmd msg
