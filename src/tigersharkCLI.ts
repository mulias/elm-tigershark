import * as fs from "fs";
import * as path from "path";
import { generateTypeDeclarations } from "./generateTypeDeclarations";
import { tryReadConfig, isSupportedVersion } from "./elmConfig";

var isWriting = false;

process.on("SIGTERM", () => {
  if (!isWriting) {
    console.log("Process terminated early, no output written.");
    process.exit(0);
  }
});

const elmConfig = tryReadConfig();

if (!isSupportedVersion(elmConfig)) {
  console.log("Unsupported Elm version.");
  process.exit(1);
}

const [_scriptRunner, _script, ...args] = process.argv;

const versionFlag = args.includes("--version");
const inputArgs = args.filter(s => !s.startsWith("--"));
const outputArgs = args.filter(s => s.startsWith("--output="));

if (versionFlag) {
  const version = require("../package.json")["version"];
  console.log(version);
  process.exit(0);
}

const inputInvalid = inputArgs.length !== 1 || !inputArgs[0].endsWith(".elm");
const outputInvalid =
  outputArgs.length !== 1 || !outputArgs[0].endsWith(".d.ts");

if (inputInvalid || outputInvalid) {
  process.exit(1);
}

const inputFile = inputArgs[0];
const outputFile = outputArgs[0].replace(/^--output=/, "");

const inputFileSource = fs.readFileSync(inputFile).toString();

generateTypeDeclarations(inputFileSource, declarations => {
  const outputFolder = path.dirname(outputFile);
  if (!fs.existsSync(outputFolder)) {
    fs.mkdirSync(outputFolder);
  }

  isWriting = true;
  fs.writeFileSync(outputFile, declarations);
  isWriting = false;
  process.exit(0);
});
