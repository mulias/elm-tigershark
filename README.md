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
- [ ] Multi-module parsing
- [ ] Good error messages, CLI enhancements
- [ ] Real README documentation

### Later enhancements

Things I'm thinking about now, but should be done later.

- Support pre-0.19 Elm.
- Flag to try type checking the code first with the elm compiler, and optionally
  specify the location of the `elm make` executable. Note: I'm doing this right
  now by running `elm-make foo && tigershark foo`.
- Flag to use local prettier install to format declaration files, and optionally
  specify the location of the prettier executable. Note: I'm doing this right
  now by running `tigershark foo && prettier foo`.
- Flag to set if the declaration file matches on `*.elm`, or specific modules.
- Write custom "isPortsModule" parser so that we don't have to fully parse every
  imported module to find ones that use ports.
- Fuzz tests?
- Use `elm-program-test` to test the worker program end-to-end.
- And/Or, do full end-to-end testing like `elm-typescript-interop` by generating
  and diffing files.
- Windows file path support.
- Auto generate TS types, encoders, and decoders for message passing ports

### The name

This isn't a useful tool yet so it doesn't have a useful tool name. TypeScript
and Tigershark sound a bit similar. That's all I've got.
