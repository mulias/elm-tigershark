const webpack = require("webpack");
const path = require("path");
const { ElmTigersharkPlugin } = require("elm-tigershark");

module.exports = (env, argv) => ({
  entry: {
    index: "./src/index.ts",
    tigersharkCLI: "./src/tigersharkCLI.ts"
  },
  target: "node",
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "[name].js",
    libraryTarget: "commonjs2"
  },
  module: {
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: "elm-webpack-loader",
            options: {
              optimize: argv.mode === "production"
            }
          }
        ]
      },
      { test: /\.ts$/, loader: "ts-loader" }
    ]
  },
  plugins: [
    new ElmTigersharkPlugin(
      "elm make src/Main/Program.elm --output=/dev/null && tigershark src/Main/Program.elm --output=src/declarations/elm.d.ts --tsModule='*.elm' && prettier src/declarations/elm.d.ts --write"
    )
  ],
  resolve: {
    extensions: [".js", ".ts", ".elm"]
  }
});
