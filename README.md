# elm-tigershark

WIP/Exploratory project for generating TypeScript type declarations for Elm
programs. Based off of `elm-typescript-interop`.

### Roadmap

- [x] Setup TypeScript and Elm project
- [x] Setup Elm testing
- [ ] Use `elm-syntax` to parse main module source and extract relivent ASTs
- [ ] Parse interoperable Elm types into TypeScript types
- [ ] Add types for flags
- [ ] Add types for all ports in file
- [ ] CLI tool
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
    |                                       unable to parse module source
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
convert flags to InteropOrAliases    -----> Fail, type is not interoperable
convert ports to InteropOrAliases
    |
    v
resolve local aliases                -----> Fail, type is not interoperable
    |
    v
resolve imported aliases             -----> Fail, alias type not found
    |                                             type is not interoperable
    |                                             unable to find import
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

- Write custom "isPortsModule" parser so that we don't have to parse every
  import to find ones that use ports.
- Fuzz tests for
    - Always extracts name from module
    - Always converts flags of interoperable types
    - Always collects local ports
- Request files as needed from node, instead of reading all files during
  startup.
- Flag to use local prettier install to format declaration files

### The name

This isn't a useful tool yet so it doesn't have a useful tool name. TypeScript
and Tigershark sound a bit similar. That's all I've got.
