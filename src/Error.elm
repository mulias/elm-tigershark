module Error exposing (Error(..), toString)

{-| Catalog of possible failure cases in generating a type declaration file.
The `Error` type accounts for errors in Elm, but some failure cases can happen
in the node wrapper.
-}


{-| Fatal processing errors that should be reported to the user.
-}
type Error
    = ParsingFailure
    | MissingModuleDefinition
    | MissingModuleName
    | MissingMainFunction
    | MissingMainSignature
    | MainNotAProgram
    | ModuleNotFound
    | UninteroperableType
    | AliasTypesNotSupported String
    | InvalidPortSignature


toString : Error -> String
toString error =
    case error of
        ParsingFailure ->
            "ParsingFailure"

        MissingModuleDefinition ->
            "MissingModuleDefinition"

        MissingModuleName ->
            "MissingModuleName"

        MissingMainFunction ->
            "MissingMainFunction"

        MissingMainSignature ->
            "MissingMainSignature"

        MainNotAProgram ->
            "MainNotAProgram"

        ModuleNotFound ->
            "ModuleNotFound"

        UninteroperableType ->
            "UninteroperableType"

        AliasTypesNotSupported string ->
            "AliasTypesNotSupported " ++ string

        InvalidPortSignature ->
            "InvalidPortSignature"
