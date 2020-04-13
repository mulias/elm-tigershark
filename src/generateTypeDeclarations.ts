import { Elm } from "./Main/Program.elm";
import { Flags } from "./elmProgram/types";
import { ProjectFile, ProjectFilePath } from "./elmProgram/projectFile";

export interface Callbacks {
  onFetchFile: (filePath: ProjectFilePath, fileFetched: (projectFile: ProjectFile) => void) => void;
  onWriteFile: (declarations: string) => void;
  onReportError: (error: string) => void;
}

export const generateTypeDeclarations = (
  flags: Flags<typeof Elm.Main.Program>,
  { onFetchFile, onWriteFile, onReportError }: Callbacks
): void => {
  const program = Elm.Main.Program.init({ flags });

  program.ports.fetchFile.subscribe(projectFilePath =>
    onFetchFile(projectFilePath, program.ports.fileFetched.send)
  );
  program.ports.writeFile.subscribe(onWriteFile);
  program.ports.reportError.subscribe(onReportError);
};
