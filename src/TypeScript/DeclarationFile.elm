module TypeScript.DeclarationFile exposing (write)

import String.Interpolate exposing (interpolate)
import TypeScript.Writer as Writer


type alias DeclarationFile =
    { namespace : String
    , docs : Maybe String
    , flags : Maybe String
    , ports : List { name : String, body : String }
    }


{-| Given formatted strings, construct the full file.
-}
write : DeclarationFile -> String
write { namespace, docs, flags, ports } =
    Writer.toString <|
        Writer.file
            [ Writer.prefix
            , Writer.blankLine
            , Writer.namespace
                { name = "Elm", docs = Nothing }
                [ Writer.namespace
                    { name = namespace, docs = docs }
                    [ Writer.ports ports
                    , Writer.initFn namespace flags
                    ]
                ]
            ]
