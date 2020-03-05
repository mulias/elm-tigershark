import { Elm } from "./Main.elm";

export const generateTypeDeclarations = (
  inputFileSource: string,
  callback: (declarations: string) => void
): void => {
  const program = Elm.Main.init({ flags: { inputFileSource } });

  program.ports.writeFile.subscribe(callback);
};
