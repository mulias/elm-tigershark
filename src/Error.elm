module Error exposing (Error(..))


type Error
    = ParsingFailure
    | MissingModuleDefinition
    | MissingModuleName
    | MissingMainFunction
    | MissingMainSignature
    | NestedMainModuleUnsupported
