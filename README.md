# elm-tigershark

WIP/Exploratory project for generating TypeScript type declarations for Elm
programs. Based off of `elm-typescript-interop`.

### Roadmap

- [x] Setup TypeScript and Elm project
- [x] Setup Elm testing
- [x] Use `elm-syntax` to parse main module source and extract relivent ASTs
- [x] Parse interoperable Elm types into TypeScript types
- [x] Add types for flags
- [x] Add types for all ports in file
- [x] Parse a single module to a declaration file
- [x] Programs in nested module
- [ ] De-alias local types
- [ ] CLI tool
- [ ] Good error messages
- [ ] Multi-module parsing
- [ ] Support pre-0.19 Elm

### Some notes

```
let's generate a type declaration file!
    |
    v
run `elm-tigershark src/MyApp.elm`   -----> Fail, malformed CLI args
    |
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

### Later enhancements

Things I'm thinking about now, but should be done way later.

- Write custom "isPortsModule" parser so that we don't have to fully parse every
  imported module to find ones that use ports.
- Fuzz tests for
  - Always extracts name from module
  - Always converts flags of interoperable types
  - Always collects local ports
- Request files as needed from node, instead of reading all files during
  startup.
- Flag to use local prettier install to format declaration files
- Use `elm-program-test` to test the worker program end-to-end.
- Windows file path support

### The name

This isn't a useful tool yet so it doesn't have a useful tool name. TypeScript
and Tigershark sound a bit similar. That's all I've got.
