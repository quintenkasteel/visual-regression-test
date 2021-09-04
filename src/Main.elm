module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)


main =
    Browser.sandbox { init = 1, update = update, view = view }


type Msg
    = Increment
    | Decrement


update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1


view model =
    div [ style "background" "blue" ]
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text <| "text: " ++ String.fromInt model ]
        , button [ onClick Increment ] [ text "+" ]
        ]
