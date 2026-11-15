# CLAUDE.md

## プロジェクト概要

ason.as - 個人サイト。Middleman で構成し、テンプレートは ERB、CSS は `source/stylesheets/site.css` に素の CSS で書く。トップページのアプリと登壇は `data/apps.yml`・`data/talks.yml` から描画する。記事は weblog.ason.as に移した。旧記事の URL は `moved_articles.txt` をもとに `deploy.rb` が weblog.ason.as へリダイレクトする。

## 開発環境のセットアップ

```sh
mise install        # .ruby-version の Ruby をインストール
bundle install      # gem依存関係のインストール
```

## ローカルサーバーの起動

```sh
bundle exec middleman server
```

http://localhost:4567 でアクセス。

## AWS認証

- mairuを使ってAWS認証情報を管理（ディスクにクレデンシャルを保存しない）
- `.mairu.json` にサーバーとロールの設定あり
- `mairu login personal` でログイン後に使用可能

## デプロイ

```sh
mairu exec auto -- ruby deploy.rb
```
