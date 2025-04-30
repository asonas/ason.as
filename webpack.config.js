const path = require('path');
const webpack = require('webpack');

const { NODE_ENV } = process.env;
const isProd = NODE_ENV === "production";

module.exports = {
  mode: isProd ? "production" : "development",
  entry: [
    './source/javascripts/site.js',
    './source/stylesheets/tailwind.css'
  ],
  output: {
    filename: 'site.js',
    path: __dirname + '/build/javascripts'
  },
  module: {
    rules: [
      {
        test: /\.(sc|c|sa)ss$/,
        use: [
          "style-loader",
          {
            loader: "css-loader",
            options: {
              url: true,
              sourceMap: !isProd,
              importLoaders: 1
            }
          },
          "postcss-loader"
        ]
      },
      {
        test: /\.(gif|png|jpg|eot|wof|woff|woff2|ttf|svg)$/,
        type: 'asset',
        parser: {
          dataUrlCondition: {
            maxSize: 8 * 1024
          }
        }
      }
    ]
  },
  watchOptions: {
    ignored: /node_modules/
  },
};
