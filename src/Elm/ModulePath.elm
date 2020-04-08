module Elm.ModulePath exposing (ModuleName, ModuleNamespace, ModulePath, fromNamespace, name, namespace, toNamespace)

{-| Handling references to modules and module namespaces.
-}


{-| A series of nested Elm modules, such as ["Foo", "Bar", "Baz"] for
the module namespace "Foo.Bar.Baz". There may or may not be a module
such as `src/Foo/Bar/Baz.elm` using this namespace.
-}
type alias ModuleNamespace =
    List String


{-| The name of a module, such as "Foo" for the file "src/Foo.elm".
-}
type alias ModuleName =
    String


{-| The full path to reference a module, such as `(["A", "B"], "C")` for the
module "A.B.C" located in a file such as "src/A/B/C.elm".
-}
type alias ModulePath =
    ( ModuleNamespace, ModuleName )


{-| Try to create a ModulePath from a ModuleNamespace. Returns `Nothing` if the
namespace is empty.
-}
fromNamespace : ModuleNamespace -> Maybe ModulePath
fromNamespace moduleNames =
    case List.reverse moduleNames of
        [] ->
            Nothing

        [ moduleName ] ->
            Just ( [], moduleName )

        moduleName :: moduleNamespace ->
            Just ( List.reverse moduleNamespace, moduleName )


{-| Create a ModuleNamespace form a ModulePath.
-}
toNamespace : ModulePath -> ModuleNamespace
toNamespace ( moduleNamespace, moduleName ) =
    List.append moduleNamespace [ moduleName ]


{-| Get the ModuleNamespace from a ModulePath.
-}
namespace : ModulePath -> ModuleNamespace
namespace =
    Tuple.first


{-| Get the ModuleName from a ModulePath.
-}
name : ModulePath -> ModuleName
name =
    Tuple.second
