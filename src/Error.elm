module Error exposing (Error(..))

{-| -}


{-| Fatal processing errors that should be reported to the user.
-}
type Error
    = ParsingFailure
    | MissingModuleDefinition
    | MissingModuleName
    | MissingMainFunction
    | MissingMainSignature
    | MainNotAProgram
    | ImportedModuleNotFound
    | NestedMainModuleUnsupported
