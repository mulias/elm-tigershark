```
let's generate a type declaration file!
    |
    v
run `tigershark src/Main.elm --output=src/main.d.ts`
    |                                |
    |                                `----> Fail, malformed CLI args
    v
locate and parse Elm project file    -----> Fail, project file not found
    |                                             unsupported Elm version
    v
collect all project file paths and
source code, pass over to Elm
    |
    v
initialize module cache
    |
    v
parse module with `elm-syntax`       -----> Fail, unable to find module in cache
    |                                             unable to parse module source
    v
collect module name, main function   -----> Fail, no main or no signature
    |
    v
extract flags type AST from main sig -----> Fail, main is not a `Program`
    |
    v
if ports module, search module       -----> Fail, unable to find import in cache
cache and collect port definitions                unable to parse module source
    |
    v
convert flags/ports to Typescript    -----> Fail, type is not interoperable
type strings, resolve local and                   alias type not found
imported aliases                                  unable to find import
    |                                             unable to parse module source
    v
stringify module name, flags, ports
    |
    v
generate declaration file
    |
    v
write output file                    -----> Fail, error writing output
```
