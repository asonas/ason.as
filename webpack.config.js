const path = require('path');
const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');

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
          // CSSは実体ファイルへ抽出して<link>で配信する。
          // style-loaderのようにJS経由で注入するとスタイル適用がJS実行待ちになり、
          // レンダリングをブロックするため使わない。
          MiniCssExtractPlugin.loader,
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
  plugins: [
    new MiniCssExtractPlugin({
      // output.path が build/javascripts のため、一つ上の build/stylesheets へ出力する。
      filename: '../stylesheets/site.css'
    })
  ],
  optimization: {
    minimizer: [
      // JSのデフォルトminimizer(Terser)を維持しつつCSSのminifyを追加する。
      '...',
      new CssMinimizerPlugin()
    ]
  },
  watchOptions: {
    ignored: /node_modules/
  },
};
