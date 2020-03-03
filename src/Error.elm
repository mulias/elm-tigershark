module Error exposing (Error(..))

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
    | ImportedModuleNotFound
    | UninteroperableType
    | NestedMainModuleUnsupported
    | AliasTypesNotSupported
    | UnknownPortSignature
