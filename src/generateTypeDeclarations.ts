import { Elm } from "./Main.elm";
import { Flags } from "./elmAppTypes";

export const generateTypeDeclarations = (
  flags: Flags<typeof Elm.Main>,
  successCallback: (declarations: string) => void,
  errorCallback: (error: string) => void
): void => {
  const program = Elm.Main.init({ flags });

  program.ports.writeFile.subscribe(successCallback);
  program.ports.reportError.subscribe(errorCallback);
};
