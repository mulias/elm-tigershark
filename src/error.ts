/**
 * Catalog of possible failure cases in generating a type declaration file. The
 * `Errors` type accounts for errors in Node, but some failure cases can happen
 * in the called Elm code.
 */
export type Errors = "MalformedCLIArgs" | "ElmProjectFileNotFound" | "UnsupportedElmVersion" | "WritingOutputFailed";
