import { Elm } from "./Main.elm";
import { Flags } from "./elmAppTypes";
import { ProjectFile, ProjectFilePath } from "./elmFiles";

export interface Callbacks {
  onFetchFile: (
    filePath: ProjectFilePath,
    fileFetched: (projectFile: ProjectFile) => void
  ) => void;
  onWriteFile: (declarations: string) => void;
  onReportError: (error: string) => void;
}

export const generateTypeDeclarations = (
  flags: Flags<typeof Elm.Main>,
  { onFetchFile, onWriteFile, onReportError }: Callbacks
): void => {
  const program = Elm.Main.init({ flags });

  program.ports.fetchFile.subscribe(projectFilePath =>
    onFetchFile(projectFilePath, program.ports.fileFetched.send)
  );
  program.ports.writeFile.subscribe(onWriteFile);
  program.ports.reportError.subscribe(onReportError);
};
