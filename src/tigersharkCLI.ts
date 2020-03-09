import * as fs from "fs";
import * as path from "path";
import { generateTypeDeclarations } from "./generateTypeDeclarations";
import { tryReadConfig, isSupportedVersion } from "./elmConfig";
import { elmProjectFiles, pathFromSourceDir } from "./elmFiles";

// Protect process from SIGTERM requests while writing output

var isWriting = false;

process.on("SIGTERM", () => {
  if (!isWriting) {
    console.log("Process terminated early, no output written.");
    process.exit(0);
  }
});

// Get the `elm.json` file and retrieve needed info. Fail if running on a
// project with an unsupported Elm version.

const elmConfig = tryReadConfig();

if (!isSupportedVersion(elmConfig)) {
  console.log("Unsupported Elm version.");
  process.exit(1);
}

// Parse cli args

const [_scriptRunner, _script, ...args] = process.argv;

const versionFlag = args.includes("--version");
const inputArgs = args.filter(s => !s.startsWith("--"));
const outputArgs = args.filter(s => s.startsWith("--output="));

// If the version flag is passed then ignore everything else and return the app version

if (versionFlag) {
  const version = require("../package.json")["version"];
  console.log(version);
  process.exit(0);
}

// Otherwise finish parsing cli args

const inputInvalid = inputArgs.length !== 1 || !inputArgs[0].endsWith(".elm");
const outputInvalid =
  outputArgs.length !== 1 || !outputArgs[0].endsWith(".d.ts");

if (inputInvalid || outputInvalid) {
  process.exit(1);
}

// the input file path is relative to one of the projectDirectories in the elmConfig
const inputFilePath = pathFromSourceDir(inputArgs[0], elmConfig);
// the output file path can be anywhere
const outputFileLocation = outputArgs[0].replace(/^--output=/, "");

// Read all files in the project

const projectFiles = elmProjectFiles(elmConfig);

// Call Elm code to turn cli args and project source into declaration files

generateTypeDeclarations({ inputFilePath, projectFiles }, declarations => {
  const outputFolder = path.dirname(outputFileLocation);
  if (!fs.existsSync(outputFolder)) {
    fs.mkdirSync(outputFolder);
  }

  isWriting = true;
  fs.writeFileSync(outputFileLocation, declarations);
  isWriting = false;
  process.exit(0);
});
