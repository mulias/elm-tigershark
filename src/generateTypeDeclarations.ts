import { Elm } from "./Main.elm";

export type ElmApp<Flags, Ports> = {
  init: (options: { flags: Flags }) => { ports: Ports };
};

export type Ports<T extends ElmApp<any, any>> = T extends ElmApp<any, infer P>
  ? P
  : never;

export type Flags<T extends ElmApp<any, any>> = T extends ElmApp<infer F, any>
  ? F
  : never;

export const generateTypeDeclarations = (
  flags: Flags<typeof Elm.Main>,
  callback: (declarations: string) => void
): void => {
  const program = Elm.Main.init({ flags });

  program.ports.writeFile.subscribe(callback);
};
