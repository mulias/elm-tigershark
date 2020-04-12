module Main.Error exposing (Error(..), FatalError(..), NonFatalError(..), toString)

{-| Catalog of possible failure cases in generating a type declaration file.
The `Error` type accounts for errors in Elm, but some failure cases can happen
in the node wrapper.
-}


{-| Fatal processing errors that should be reported to the user.
-}
type Error
    = Fatal FatalError
    | NonFatal NonFatalError


type FatalError
    = ParsingFailure
    | MissingModuleDefinition
    | MissingModuleName
    | MissingMainSignature
    | MainNotAProgram
    | FileNotFound
        { modulePath : ( List String, String )
        }
    | EmptyFilePath
    | UninteroperableType
    | AliasTypeNotFound
    | SubstituteTypeNotFound
    | TypeVariableNotFound
    | InvalidPortSignature
    | NoDeclarationsToGenerate


type NonFatalError
    = MissingMainFunction
    | FileNotRead
        { sourceDirectory : List String
        , modulePath : ( List String, String )
        }


toString : FatalError -> String
toString error =
    case error of
        ParsingFailure ->
            "ParsingFailure"

        MissingModuleDefinition ->
            "MissingModuleDefinition"

        MissingModuleName ->
            "MissingModuleName"

        MissingMainSignature ->
            "MissingMainSignature"

        MainNotAProgram ->
            "MainNotAProgram"

        FileNotFound _ ->
            "FileNotFoundBar"

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

        NoDeclarationsToGenerate ->
            "NoDeclarationsToGenerate"
