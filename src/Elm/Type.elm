module Elm.Type exposing (dealiasAndNormalize)

{-| TODO
-}

import Elm.AST exposing (ExposingAST(..), ImportAST, TypeAliasAST, TypeAnnotationAST(..), toExposingAST, toImportAST, toTypeAliasAST)
import Elm.ModulePath exposing (ModuleName)
import Elm.Project as Project exposing (FindBy(..), Project)
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Node as Node
import Error exposing (Error)
import Maybe.Extra
import Result.Extra
import Util.Elm.Syntax.File exposing (fileModuleNameList, moduleExposes)
import Util.List


type alias Type =
    { moduleContext : List ModuleName
    , typeAnnotation : TypeAnnotationAST
    }


type alias TypeToFind =
    { moduleContext : List ModuleName
    , modulePrefix : List ModuleName
    , typeName : String
    , typeArgs : List TypeAnnotationAST
    }


type alias FoundType =
    { moduleContext : List ModuleName
    , generics : List String
    , typeAnnotation : TypeAnnotationAST
    }


dealiasAndNormalize : Project -> Type -> Result Error Type
dealiasAndNormalize project { moduleContext, typeAnnotation } =
    case typeAnnotation of
        TypedAST ( modulePrefix, typeName ) typeArgs ->
            let
                typeToFind =
                    { moduleContext = moduleContext
                    , modulePrefix = modulePrefix
                    , typeName = typeName
                    , typeArgs = typeArgs
                    }

                foundType =
                    find project typeToFind

                subbedTypeAnnotation =
                    Result.andThen (substitute typeToFind) foundType
            in
            Result.map2 Type
                (Result.map .moduleContext foundType)
                subbedTypeAnnotation

        _ ->
            Err Error.SubstituteTypeNotFound


{-| Try to find an alias to substitute in for an uninteroperable value. First
look in the unknown type's module, and try to find a local alias which can be
substituted for the value. Next try to match the unknown type to an import for
a JSON value. Finally, search through imported modules that might be exposing
the type.
-}
find : Project -> TypeToFind -> Result Error FoundType
find project typeToFind =
    case Project.readFileWith (Module typeToFind.moduleContext) project of
        Ok file ->
            getLocalAlias file typeToFind
                |> Result.Extra.orElseLazy (\_ -> getJsonValueType file typeToFind)
                |> Result.Extra.orElseLazy (\_ -> getImportedAlias project file typeToFind)

        Err error ->
            Err error


{-| Create a new type annotation where the unknown type is replaced with the alias.
-}
substitute : TypeToFind -> FoundType -> Result Error TypeAnnotationAST
substitute typeToFind foundType =
    let
        { typeArgs } =
            typeToFind

        { generics, typeAnnotation } =
            foundType

        typeVarAssoc =
            Util.List.zip generics typeArgs

        substituteTypeVar typeVar =
            Util.List.assocFind typeVar typeVarAssoc

        innerFoundType innerTypeAnnotation =
            { foundType | typeAnnotation = innerTypeAnnotation }
    in
    case typeAnnotation of
        GenericTypeAST typeVar ->
            substituteTypeVar typeVar
                |> Result.fromMaybe Error.TypeVariableNotFound

        TypedAST ( modulePrefix, typeName ) foundTypeArgs ->
            foundTypeArgs
                |> List.map innerFoundType
                |> List.map (substitute typeToFind)
                |> Result.Extra.combine
                |> Result.map
                    (\subbedTypeArgs ->
                        TypedAST ( modulePrefix, typeName ) subbedTypeArgs
                    )

        UnitAST ->
            Ok UnitAST

        TupledAST tupleTypes ->
            tupleTypes
                |> List.map innerFoundType
                |> List.map (substitute typeToFind)
                |> Result.Extra.combine
                |> Result.map TupledAST

        RecordAST recordFields ->
            recordFields
                |> List.map
                    (\( fieldName, recordType ) ->
                        substitute typeToFind (innerFoundType recordType)
                            |> Result.map (Tuple.pair fieldName)
                    )
                |> Result.Extra.combine
                |> Result.map RecordAST

        GenericRecordAST recordTypeVar constraint ->
            substituteTypeVar recordTypeVar
                |> Result.fromMaybe Error.TypeVariableNotFound

        FunctionTypeAnnotationAST typeA typeB ->
            Result.map2 FunctionTypeAnnotationAST
                (substitute typeToFind (innerFoundType typeA))
                (substitute typeToFind (innerFoundType typeB))


{-| Search through the declarations in the file and find the first type alias
declaration that matches the name of the unknown type, and has the same generic
type argument arity.
-}
getLocalAlias : File -> TypeToFind -> Result Error FoundType
getLocalAlias file { moduleContext, modulePrefix, typeName, typeArgs } =
    if List.isEmpty modulePrefix then
        aliasDeclarations file
            |> Util.List.findMap
                (\{ name, generics, typeAnnotation } ->
                    if
                        (List.length generics == List.length typeArgs)
                            && (name == typeName)
                    then
                        Just
                            { moduleContext = fileModuleNameList file
                            , generics = generics
                            , typeAnnotation = typeAnnotation
                            }

                    else
                        Nothing
                )
            |> Result.fromMaybe Error.AliasTypeNotFound

    else
        Err Error.AliasTypeNotFound


{-| If the unknown type is the correct shape to be a `Json.Decode.Value` or
`Json.Encode.Value`, and the type is appropriately imported, then return an AST
with the full module path. This is a special case where an external package is
known to contain an interoperable type.
-}
getJsonValueType : File -> TypeToFind -> Result Error FoundType
getJsonValueType file typeToFind =
    let
        { moduleContext, modulePrefix, typeName, typeArgs } =
            typeToFind
    in
    if (typeName == "Value") && List.isEmpty typeArgs then
        jsonCodecImports file
            |> List.filter (importCouldIncludeType typeToFind)
            |> List.head
            |> Result.fromMaybe Error.AliasTypeNotFound
            |> Result.map
                (\jsonImport ->
                    { moduleContext = jsonImport.moduleName
                    , generics = []
                    , typeAnnotation = TypedAST ( jsonImport.moduleName, "Value" ) []
                    }
                )

    else
        Err Error.AliasTypeNotFound


{-| Search through the file's imported modules that might be importing the
unknown type. Find the first alias definition in an imported module which
matches the unknown type and is exposed by its module. Elm does not allow for
re-exporting imports, so we do not search recursively.
-}
getImportedAlias : Project -> File -> TypeToFind -> Result Error FoundType
getImportedAlias project file typeToFind =
    file.imports
        |> List.map (Node.value >> toImportAST)
        |> List.filter (importCouldIncludeType typeToFind)
        |> Util.List.findMapResult
            (\{ moduleName } ->
                Project.readFileWith (Module moduleName) project
                    |> Result.andThen
                        (\importFile ->
                            if moduleExposes importFile typeToFind.typeName then
                                getLocalAlias importFile { typeToFind | moduleContext = moduleName, modulePrefix = [] }

                            else
                                Err Error.AliasTypeNotFound
                        )
            )
            Error.AliasTypeNotFound
        -- Cover case where all of the modules in the list are extrnal
        -- libraries. We want to return the AliasTypeNotFound error,
        -- instead of the ModuleNotFound error.
        |> Result.mapError (always Error.AliasTypeNotFound)


{-| Get all alias declarations from a file.
-}
aliasDeclarations : File -> List TypeAliasAST
aliasDeclarations file =
    file.declarations |> List.map (Node.value >> getAliasDeclaration) |> Maybe.Extra.values


{-| Get the module imports for `Json.Encode` and `Json.Decode`, if present.
-}
jsonCodecImports : File -> List ImportAST
jsonCodecImports file =
    file.imports
        |> List.map (Node.value >> toImportAST)
        |> List.filter
            (\{ moduleName } ->
                moduleName == [ "Json", "Decode" ] || moduleName == [ "Json", "Encode" ]
            )


{-| Returns true if the import could be used to reference the unknown type.
Multiple module imports could return true for this test, since an import that
exposes everything through the `exposing (..)` always returns true.
-}
importCouldIncludeType : TypeToFind -> ImportAST -> Bool
importCouldIncludeType { modulePrefix, typeName } { moduleName, moduleAlias, exposingList } =
    let
        typeReferenceToFind =
            ( modulePrefix, typeName )

        withFullModuleName =
            Just ( moduleName, typeName )

        withModuleAlias =
            case moduleAlias of
                Just aliasName ->
                    Just ( aliasName, typeName )

                Nothing ->
                    Nothing

        directReference =
            case exposingList of
                Just All ->
                    Just ( [], typeName )

                Just (Explicit list) ->
                    if List.member typeName list then
                        Just ( [], typeName )

                    else
                        Nothing

                Nothing ->
                    Nothing
    in
    [ withFullModuleName, withModuleAlias, directReference ]
        |> Maybe.Extra.values
        |> List.any ((==) typeReferenceToFind)


getAliasDeclaration : Declaration -> Maybe TypeAliasAST
getAliasDeclaration declaration =
    case declaration of
        AliasDeclaration typeAlias ->
            Just (toTypeAliasAST typeAlias)

        _ ->
            Nothing


numTypeArguments : TypeAnnotationAST -> Int
numTypeArguments typeAnnotation =
    case typeAnnotation of
        TypedAST _ typeArgs ->
            List.length typeArgs

        _ ->
            0
