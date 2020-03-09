import * as fs from "fs";
import * as glob from "glob";
import { ElmConfig } from "./elmConfig";

export interface ElmFile {
  sourceDirectory: string;
  filePath: string;
  contents: string;
}

export const elmProjectFiles = (config: ElmConfig): ElmFile[] =>
  flatten(usedDirectories(config.sourceDirectories).map(dirFiles));

const usedDirectories = (dirList: string[]): string[] =>
  dirList.filter(sourcePath => fs.existsSync(sourcePath));

const dirFiles = (dir: string): ElmFile[] => {
  const fullPaths = glob.sync(`${dir}/**/*.elm`, {
    sync: true,
    ignore: ["**/node_modules/**/*", "**/elm-stuff/**/*"]
  });

  return fullPaths.map(fullPath => ({
    sourceDirectory: dir,
    filePath: fullPath.slice(`${dir}/`.length),
    contents: fs.readFileSync(fullPath).toString()
  }));
};

export const pathFromSourceDir = (path: string, config: ElmConfig): string => {
  const srcDir = config.sourceDirectories.find(dir => path.startsWith(dir));
  return srcDir !== undefined ? path.slice(`${srcDir}/`.length) : path;
};

// Helpers

const flatten = <T>(list: Array<Array<T>>): Array<T> =>
  ([] as Array<T>).concat(...list);
