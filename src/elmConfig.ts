import * as fs from "fs";

interface ElmConfig {
  elmVersion: string;
  sourceDirectories: string[];
}

export const tryReadConfig = (): ElmConfig => parseConfig(readConfigFile());

const readConfigFile = (): unknown => {
  if (fs.existsSync("./elm.json")) {
    return JSON.parse(fs.readFileSync("./elm.json").toString());
  } else {
    console.error(
      "I couldn't find an `elm.json` file. Please run `elm-tigershark` from your Elm project's root folder."
    );
    process.exit(1);
  }
};

const parseConfig = (config: unknown): ElmConfig => {
  if (
    config &&
    typeof config === "object" &&
    config !== null &&
    hasProp(config, "elm-version") &&
    hasProp(config, "source-directories") &&
    isArrayOfStrings(config["source-directories"]) &&
    typeof config["elm-version"] === "string"
  ) {
    return {
      elmVersion: config["elm-version"],
      sourceDirectories: config["source-directories"]
    };
  } else {
    process.exit(1);
  }
};

export const isSupportedVersion = ({ elmVersion }: ElmConfig): boolean =>
  elm19VersionStrings.includes(elmVersion);

const elm19VersionStrings = ["0.19.0", "0.19.1"];
// Helpers

const hasProp = <T extends {}, K extends PropertyKey>(
  obj: T,
  prop: K
): obj is T & Record<K, unknown> => obj.hasOwnProperty(prop);

const isArrayOfStrings = (xs: unknown): xs is Array<string> =>
  Array.isArray(xs) && xs.every(x => typeof x === "string");
