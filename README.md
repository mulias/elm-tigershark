# Archived: Check out [elm-ts-json](https://github.com/dillonkearns/elm-ts-json)!

Back in March of 2020 I had two big problems in my life: one was a global pandemic the other was that the tool [`elm-typescript-interop`](https://github.com/dillonkearns/elm-typescript-interop) was no longer getting maintained and had some inconvenient limitations.

I couldn't do much about that first problem, so I figured I might as well take a swing at the second one! I built out an MVP and then reached out to Dillon Kearns to talk about transitioning the old `elm-typescript-interop` codebase over to my code. Dillon was supportive, but pointed out a few important edge cases that I wasn't handling, and unfortunately would be very hard to address with my approach. I let the code sit for a while, in the hopes that I'd eventually figure out a solution. Thankfully I didn't have to because a few years later Dillon released `elm-ts-json` which is a much more elegant solution to typed interop. Thanks Dillon!

# Elm Tigershark

Enjoy type-safe interop between Elm and TypeScript with automatically typed
flags and ports.

This tool is meant as a mostly drop-in replacement for
[`elm-typescript-interop`](https://github.com/dillonkearns/elm-typescript-interop),
so if you don't know what's up start there. While `elm-typescript-interop`
supports Elm 0.18 well but has known bugs with Elm 0.19, `elm-tigershark` only
supports Elm 0.19.

## Installation

Tigershark is an npm package and can be installed via `npm i elm-tigershark` or
similar commands.

## Usage

Unlike `elm-typescript-interop`, tigershark uses CLI arguments similar to the
Elm compiler in order to specify the Elm input files and generated output file.
This level of control allows tigershark to support some interop use cases that
are not possible with `elm-typescript-interop`.

#### A single Elm program

For a project with one Elm program, we might compile our Elm code and generate
type declarations like this:

```
elm make src/Main.elm --output=src/elm-main.js
tigershark src/Main.elm --output=src/elm-main.d.ts
```

Importantly, the compiled javascript file and type declaration file have the
same name so when we use an import directive, such as `import {Elm} from
'elm-main'`, TypeScript is able to match up the generated types to the compiled
Elm code. We could instead use an index file, in this case meaning
`--output=src/elm-main/index.d.ts`

#### Multiple Elm programs

For a project with multiple Elm programs, we may choose to compile each program
separately, like above, or compile multiple Elm programs together into one
javascript output. In this later case we need to specify the same files when
calling `elm make` and `tigershark` so that the output includes types for each
Elm program:

```
elm make src/*.elm --output=src/elm-programs.js
tigershark src/*.elm --output=src/elm-programs.d.ts
```

Once again, the `.d.ts` type declaration file name should match the file name of
the compiled javascript asset. Like `elm make`, tigershark will identify which
of the provided Elm input files contains a program main function and produces a
type for each program.

#### Webpack and other asset loaders

If we're using Elm with `elm-webpack-loader` or some other asset management
system, then we will have to take advantage of TypeScript's [wildcard module
declarations](https://www.typescriptlang.org/docs/handbook/modules.html#wildcard-module-declarations)
feature to associate types with imported Elm files. This use case has some
unfortunate nuance, so we'll step through it carefully.

When using `elm-webpack-loader` the build system identifies which Elm files to
find and compile based off of javascript imports with the `.elm` extension.
Given two Elm programs, `Foo.elm` and `Bar.elm`, we might import and use the
programs like this:

```
import { Elm as ElmFooApp } from "Foo.elm";
import { Elm as ElmBarApp } from "Bar.elm";

...

ElmFooApp.Foo.init(fooNode, fooFlags)
ElmFooApp.Bar.init(barNode, barFlags)
```
In previous examples we noted that Typescript pairs untyped javascript files to
type declaration files based on file name. How do we accomplish this pairing when
the file name has an extension? Unfortunately we can't. The only way to
associate types to our Elm imports is by wrapping the type declarations in a
wildcard module, specifically `declare module '*.elm'`. This directive tells
TypeScript that every file imported with a `.elm` extension will use the
module's type, regardless of file name.

Here's how we might generate types for our Elm and Typescript project that uses
webpack to manage Elm compilation:

```
tigershark src/Foo.elm src/Bar.elm --output=src/elm.d.ts --tsModule='*.elm'
```
The name of the output file is no longer relevant, since it's superseded by the
wildcard module declaration. The `tsModule` argument can be changed to support
different asset loaders which might use a different import syntax.

Finally, `elm-tigershark` comes with a webpack plugin to automatically
regenerate type declarations when Elm files are changed. The plugin API has not
yet been finalized.


## Roadmap to 1.0.0

- [ ] Fix detection of indirect port use
- [ ] Basic error messages
- [ ] Basic CLI help output
- [ ] Improve ElmTigersharkWebpackPlugin API

## Known issues

- The current method of finding ports associated to an Elm program is flawed and
  needs to be rewritten. If you declare a port in a file, but then wrap the
  port in a different function and export the wrapping function, the indirect
  use of the port will not be detected.
- In Elm 0.19 the `--optimize` flag removes unused ports from the compiled
  javascript output. These unused ports are still included in the generated
  type definition, but calling the port functions from javascript produces a
  runtime error.

## Future enhancements

- Auto generate TS types, encoders, and decoders for message passing ports.
- On init, preemptively read files that we know will be needed.
- Make read file requests for multiple files at once.
- Write custom "isPortModule" parser so that we don't have to fully parse a
  file with `elm-syntax` to find out if it's declared as a `port module`.
- Cache ASTs in the `Project` so that files don't have to be repeatedly
  re-parsed.

## The name

This isn't a useful tool yet so it doesn't have a useful tool name. TypeScript
and Tigershark sound a bit similar. That's all I've got.
