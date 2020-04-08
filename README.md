# elm-tigershark

WIP/Exploratory project for generating TypeScript type declarations for Elm
programs. Based off of `elm-typescript-interop`.

### Roadmap to 1.0.0

- [x] Setup TypeScript and Elm project
- [x] Setup Elm testing
- [x] Use `elm-syntax` to parse main module source and extract relivent ASTs
- [x] Convert interoperable Elm types into TypeScript types
- [x] Add types for flags
- [x] Add types for all ports in file
- [x] Parse a single module to a declaration file
- [x] CLI tool
- [x] Resolve type aliases
- [x] Include imported ports
- [x] Multi-module parsing
- [ ] Good error messages, CLI enhancements
- [ ] Real README documentation

### Later enhancements

Things I'm thinking about now, but should be done later.

- Support pre-0.19 Elm.
- Write custom "isPortsModule" parser so that we don't have to fully parse every
  imported module to find ones that use ports.
- Auto generate TS types, encoders, and decoders for message passing ports

### The name

This isn't a useful tool yet so it doesn't have a useful tool name. TypeScript
and Tigershark sound a bit similar. That's all I've got.
