const webpack = require("webpack");
const path = require("path");

module.exports = (env, argv) => ({
  entry: "./src/index.ts",
  target: "node",
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "bundle.js",
    publicPath: "/"
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
