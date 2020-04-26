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
- [ ] Basic error messages
- [ ] Basic CLI help output
- [ ] Elm 0.18 support
- [ ] Improve ElmTigersharkWebpackPlugin API
- [ ] README documentation

### Future enhancements

- Auto generate TS types, encoders, and decoders for message passing ports.
- On init, preemptively read files that we know will be needed.
- Make read file requests for multiple files at once.
- Write custom "isPortModule" parser so that we don't have to fully parse a
  file with `elm-syntax` to find out if it's declared as a `port module`.
- Cache ASTs in the `Project` so that files don't have to be repeatedly
  re-parsed.

### The name

This isn't a useful tool yet so it doesn't have a useful tool name. TypeScript
and Tigershark sound a bit similar. That's all I've got.
