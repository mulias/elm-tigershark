// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/mulias/elm-tigershark
// Type definitions for using Elm programs in TypeScript

export namespace Elm {
  namespace Main {
    export interface App {
      ports: {
        fromElm: {
          subscribe(callback: (data: string) => void): void;
        };
        toElm: {
          send(data: string): void;
        };
      };
    }
    export function init(options: {
      node?: HTMLElement | null;
      flags: null;
    }): Elm.Main.App;
  }
}
