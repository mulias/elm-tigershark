module TypeScript.DeclarationFile exposing (DeclarationFile, write)

import String.Interpolate exposing (interpolate)
import TypeScript.Writer as Writer


type alias DeclarationFile =
    { moduleName : String
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
            , Writer.newline
            , Writer.namespace
                { docs = Nothing, export = True, name = "Elm" }
                [ Writer.namespace
                    { docs = docs, export = False, name = namespace }
                    [ Writer.interface
                        { export = True, name = "App" }
                        [ Writer.ports ports ]
                    , Writer.initFn namespace flags
                    ]
                ]
            ]
