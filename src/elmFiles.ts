import * as fs from "fs";
import * as glob from "glob";
import * as path from "path";
import { ElmConfig } from "./elmConfig";

// A directory path without separators, e.g. ["foo", "src"] instead of "foo/src/"
export type DirPath = string[];

// The full module path to an Elm file without separators, e.g. [["Foo", "Bar"], "Baz"]
// instead of "Foo/Bar/Baz.elm"
export type ModulePath = [string[], string];

// The location of an Elm module in the directory structure
export interface ProjectFilePath {
  sourceDirectory: DirPath;
  modulePath: ModulePath;
}

// Path to an Elm module file, and the read contents of that file
export interface ProjectFile extends ProjectFilePath {
  contents: string;
}

// File paths for all of the Elm modules in the project
export const allProjectFilePaths = (config: ElmConfig): ProjectFilePath[] => {
  return flatten(usedDirectories(config.sourceDirectories).map(dirFilePaths));
};

// The ProjectFilePath for a specific file path string
export const projectFilePathFromString = (
  filePath: string,
  config: ElmConfig
): ProjectFilePath => {
  const fullPath = filePath.slice(0, -4).split(path.sep);
  const srcDirPaths = config.sourceDirectories.map(dir => dir.split(path.sep));
  const sourceDirectory =
    srcDirPaths.find(
      dirPath =>
        path.join(...fullPath.slice(0, dirPath.length)) ===
        path.join(...dirPath)
    ) || [];

  return {
    sourceDirectory,
    modulePath: makeModulePath(fullPath.slice(sourceDirectory.length))
  };
};

export const readProjectFile = (
  projectFilePath: ProjectFilePath
): ProjectFile | undefined => {
  const file = makeFilePath(projectFilePath);
  if (fs.existsSync(file)) {
    return {
      ...projectFilePath,
      contents: fs.readFileSync(file).toString()
    };
  } else {
    return undefined;
  }
};

const usedDirectories = (dirList: string[]): string[] =>
  dirList.filter(sourcePath => fs.existsSync(sourcePath));

const dirFilePaths = (dir: string): ProjectFilePath[] => {
  const fullPaths = glob.sync(path.join(dir, "**", "*.elm"), {
    sync: true,
    ignore: [
      path.join("**", "node_modules", "**", "*"),
      path.join("**", "elm-stuff", "**", "*")
    ]
  });

  const sourceDirectory = dir.split(path.sep);

  return fullPaths.map(fullPath => {
    const moduleFilePath = fullPath
      .slice(0, -4)
      .split(path.sep)
      .slice(sourceDirectory.length);

    return {
      sourceDirectory,
      modulePath: makeModulePath(moduleFilePath)
    };
  });
};

const makeFilePath = ({
  sourceDirectory,
  modulePath: [moduleNamespace, moduleName]
}: ProjectFilePath): string =>
  path.join(...sourceDirectory, ...moduleNamespace, moduleName) + ".elm";

const makeModulePath = (filePath: string[]): ModulePath => {
  const [moduleName, ...moduleNamespace] = [...filePath].reverse();
  return [moduleNamespace.reverse(), moduleName];
};

const flatten = <T>(list: Array<Array<T>>): Array<T> =>
  ([] as Array<T>).concat(...list);
