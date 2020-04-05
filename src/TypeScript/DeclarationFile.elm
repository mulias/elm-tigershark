module TypeScript.DeclarationFile exposing (write)

import String.Interpolate exposing (interpolate)
import TypeScript.ProgramDeclaration exposing (ProgramDeclaration)
import TypeScript.Writers exposing (autoGeneratedFileWarning, declareModule, initFn, interface, namespace, portFns)
import Writer exposing (Writer, file, lines, newline)


{-| Construct the full declaration file and output the resulting string.
-}
write : Maybe String -> List ProgramDeclaration -> String
write declareModuleName declarations =
    declarationFile declareModuleName declarations |> Writer.toString


{-| Writer to construct the full declaration file.
-}
declarationFile : Maybe String -> List ProgramDeclaration -> Writer
declarationFile declareModuleName declarations =
    let
        elmNamespace =
            namespace { docs = Nothing, export = True, name = "Elm" }
                (List.map programDeclaration declarations)

        declarationBody =
            case declareModuleName of
                Just name ->
                    declareModule name [ elmNamespace ]

                Nothing ->
                    elmNamespace
    in
    file
        [ autoGeneratedFileWarning
        , newline
        , declarationBody
        ]


{-| Writer to create an Elm program namespace containing types for the ports
interface and init function.
-}
programDeclaration : ProgramDeclaration -> Writer
programDeclaration { moduleParents, moduleName, docs, flags, ports } =
    nestedParentNamespaces moduleParents
        [ namespace { docs = docs, export = False, name = moduleName }
            [ interface { export = True, name = "App" }
                [ portFns ports ]
            , initFn { moduleName = moduleName, flags = flags }
            ]
        ]


{-| If the program module is nested in the module structure (probably a rare
edge case), wrap the program module declaration in nested namespaces. For
example:

    ```
    namespace Foo {
      namespace Bar {
        namespace Baz {
          // program module declaration
        }
      }
    }
    ```

-}
nestedParentNamespaces : List String -> List Writer -> Writer
nestedParentNamespaces parentModuleNames children =
    List.foldr
        (\parentModuleName child ->
            namespace { docs = Nothing, export = False, name = parentModuleName }
                [ child ]
        )
        (lines children)
        parentModuleNames
