import { Elm } from "./Main.elm";
import * as fs from "fs";
import * as path from "path";

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

const program = Elm.Main.init({ flags: { inputFileSource } });

program.ports.writeFile.subscribe((declarations: string) => {
  const outputFolder = path.dirname(outputFile);
  if (!fs.existsSync(outputFolder)) {
    fs.mkdirSync(outputFolder);
  }

  fs.writeFileSync(outputFile, declarations);
  process.exit(0);
});
