const webpack = require("webpack");
const path = require("path");
const ElmTigersharkPlugin = require("src/webpackPlugin").default;

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
  plugins: [
    new ElmTigersharkPlugin(
      "elm make src/Main.elm --output=/dev/null && ./bin/tigershark src/Main.elm --output=src/main.d.ts"
    )
  ],
  resolve: {
    extensions: [".js", ".ts", ".elm"]
  }
});
