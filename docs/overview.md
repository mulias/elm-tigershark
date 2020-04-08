Overview, interaction between Elm and Node

```
Let's generate a type declaration file!
    |
    v
Run `tigershark src/Main.elm --output=src/main.d.ts`
    |                                |
    |                                `----> Fail, malformed CLI args
    v
Locate and parse Elm project file --------> Fail, project file not found
    |                                             unsupported Elm version
    v
Initialize Elm with flags:
input file paths
all project file paths
additional CLI args
    |
    v
Elm `init`
    |
    v
Create the `Project`, a file cache
for Elm modules
    |
    v
Process each input file ------------+-----> Elm requests file contents via port
                                    |           |
                                    |           v
                                    |       Read file at provided path
                                    |           |
                                    |           v
 Elm `update` <---------------------------- Pass read file back to Elm via port
    |                               |
    v                               |
Add read file to `Project` cache    |
    |                               |
    v                               |
Process each input file ------------'
    |
    v
Generate declaration file contents
    |
    v
Write output file
```

Details of the "process input files" step

```
Elm `init` or `update`
    |
    v
For each input file module
    |
    v
parse input module with `elm-syntax` -----> Fail, module file not found
    |                          |                  unable to parse module source
    |                          |
    |                          `----------> Port, request unread file
    |
    v
collect module name, main function -------> Fail, main function missing signature
    |                          |
    |                          `----------> Skip, no main function
    |
    v
extract flags type AST from main sig -----> Fail, main is not a `Program`
    |
    v
if ports module, search imported  --------> Fail, unable to parse module source
port modules for port definitions
    |                          |
    |                          `----------> Port, request unread file
    |
    v
convert flags/ports to Typescript --------> Fail, type is not interoperable
type strings, resolve local and                   alias type not found
imported aliases                                  unable to find import
    |                          |                  unable to parse module source
    |                          |
    |                          `----------> Port, request unread file
    |
    v
stringify module name, flags, ports
    |
    v
generate declaration file contents -------> Fail, all inputs skipped, no output
```
