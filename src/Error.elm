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
    | FileNotFound
        { modulePath : ( List String, String )
        }
    | FileNotRead
        { sourceDirectory : List String
        , modulePath : ( List String, String )
        }
    | EmptyFilePath
    | UninteroperableType
    | AliasTypeNotFound
    | SubstituteTypeNotFound
    | TypeVariableNotFound
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

        FileNotFound _ ->
            "FileNotFoundBar"

        FileNotRead _ ->
            "FileNotRead"

        EmptyFilePath ->
            "EmptyFilePath"

        UninteroperableType ->
            "UninteroperableType"

        AliasTypeNotFound ->
            "AliasTypeNotFound"

        SubstituteTypeNotFound ->
            "SubstituteTypeNotFound"

        TypeVariableNotFound ->
            "TypeVariableNotFound"

        InvalidPortSignature ->
            "InvalidPortSignature"
