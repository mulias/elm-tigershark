# elm-tigershark

WIP/Exploratory project for generating typescript type declarations for elm
programs. Based off of `elm-typescript-interop`.

### Roadmap

- [x] Setup typescript and elm project
- [x] Setup elm testing
- [ ] Use `elm-syntax` to parse file contents and create basic type declaration
- [ ] Parse elm types into typescript types
- [ ] Add types for flags
- [ ] Add types for all ports in file
- [ ] CLI tool
- [ ] Multi-module typing
- [ ] Support pre-0.19 elm
- [ ] Refine port types to only include ports in compiled js

### Some notes

```
let's generate a type declaration file!
    |
    v
run `elm-tigershark src/MyApp.elm`   -----> Fail, file not found
    |
    v
parse module with `elm-syntax`       -----> Fail, invalid elm code
    |
    v
collect module name, main functiona  -----> Fail, no main or signature
    |
    v
extract flags type AST from main sig -----> Fail, main is not a `Program`
    |
    v
if ports module, build dependency
graph and collect port definitions
    |
    v
convert flags to InteropOrAliases    -----> Fail, type is not interoperable
convert ports to InteropOrAliases
    |
    v
resolve local aliases                -----> Fail, type is not interoperable
    |
    v
if aliases remain, build dependency  -----> Fail, alias type not found
graph as needed, search graph                     type is not interoperable
    |
    v
stringify module name, flags, ports
    |
    v
generate declaration file
```

### The name

This isn't a useful tool yet so it doesn't have a useful tool name. TypeScript
and Tigershark sound a bit similar. That's all I've got.
