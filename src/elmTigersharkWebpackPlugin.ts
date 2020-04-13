import { ChildProcess, exec } from "child_process";
import { Compiler } from "webpack";

const isElmFile = (f: string) => f.endsWith(".elm");

/**
 * See https://stackoverflow.com/questions/43140501/can-webpack-report-which-file-triggered-a-compilation-in-watch-mode
 */
const getChangedFiles = (compiler: Compiler) => {
  // this prop seems to be undocumented and is not in the Compiler type
  const { watchFileSystem } = compiler as any;
  const watcher = watchFileSystem.watcher || watchFileSystem.wfs.watcher;

  return Object.keys(watcher.mtimes);
};

export class ElmTigersharkWebpackPlugin {
  process: ChildProcess | null;
  command: string;

  constructor(command: string) {
    this.process = null;
    this.command = command;
  }

  runCommand = () => {
    this.process = exec(this.command, (err, stdout, stderr) => {
      if (err) {
        console.error(`error running tigershark:\n ${err}`);
      } else {
        console.log(`tigershark completed with stdout:\n ${stdout}`);
        console.warn(`tigershark completed with stderr:\n ${stderr}`);
      }
      this.process = null;
    });
  };

  apply(compiler: Compiler) {
    // this should happen right before webpack runs in non-watch mode
    compiler.hooks.beforeRun.tap("ElmTigersharkPlugin", (_: Compiler) => {
      this.runCommand();
    });

    // this should happen every time changes are made in watch mode
    compiler.hooks.watchRun.tapAsync(
      "ElmTigersharkPlugin",
      (passedCompiler: Compiler, done: () => void) => {
        const elmFileChanged = getChangedFiles(passedCompiler).some(isElmFile);

        if (!elmFileChanged) {
          return done();
        }

        if (this.process !== null) {
          this.process.kill();
        }

        this.runCommand();
        done();
      }
    );
  }
}
