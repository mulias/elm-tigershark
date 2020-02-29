module Error exposing (Error(..))


type Error
    = Parsing String
    | Unsupported String
