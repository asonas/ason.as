# CLAUDE.md

## プロジェクト概要

ason.as - 個人サイト。Middleman + Webpack (Tailwind CSS) で構成。記事は weblog.ason.as に移した。旧記事の URL は `moved_articles.txt` をもとに `deploy.rb` が weblog.ason.as へリダイレクトする。

## 開発環境のセットアップ

```sh
mise install        # Ruby 3.4.5をインストール
bundle install      # gem依存関係のインストール
pnpm install        # Node依存関係のインストール
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
