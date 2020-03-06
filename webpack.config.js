const webpack = require("webpack");
const path = require("path");

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
  resolve: {
    extensions: [".js", ".ts", ".elm"]
  }
});
