// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for using Elm programs in TypeScript

declare module "*.elm" {
  export namespace Elm {
    namespace Main {
      export interface App {
        ports: {
          writeFile: {
            subscribe(callback: (data: string) => void): void;
          };
          reportError: {
            subscribe(callback: (data: string) => void): void;
          };
        };
      }
      export function init(options: {
        node?: HTMLElement | null;
        flags: {inputFileSource: string};
      }): Elm.Main.App;
    }
  }
}
