# git diff に現れたリポジトリ内のファイルパスを、CloudFront で無効化する配信URLのパスへ変換する
module InvalidationPaths
  module_function

  # ページの描画処理・ビルド設定・依存関係は、どのページの出力を変えるかをファイル名から辿れない。CSS はファイル名にハッシュが付き、参照する全ページの HTML が変わる
  SITE_WIDE_DIRECTORIES = %w[
    source/layouts/
    source/images/icons/
    source/stylesheets/
    models/
  ].freeze

  SITE_WIDE_FILES = %w[
    config.rb
    Gemfile
    Gemfile.lock
    .ruby-version
    .github/workflows/deploy.yml
  ].freeze

  TEMPLATE_EXTENSIONS = %w[.haml .erb .md].freeze

  ALWAYS = ["/", "/index.html"].freeze

  def for_files(files)
    paths = (ALWAYS + files.flat_map { |file| for_file(file) }).uniq
    paths.include?("/*") ? ["/*"] : paths
  end

  def for_file(file)
    if file == "moved_articles.txt"
      # deploy.rb がこの一覧から記事の旧 URL のリダイレクトを置き直す
      ["/articles", "/articles/*"]
    elsif file.start_with?(*SITE_WIDE_DIRECTORIES) || SITE_WIDE_FILES.include?(file)
      ["/*"]
    elsif file.start_with?("source/")
      source_paths(file.delete_prefix("source"))
    else
      []
    end
  end

  # S3 のウェブサイトエンドポイントは index.html をディレクトリURLでも返すため、両方を無効化する
  def source_paths(path)
    ext = File.extname(path)
    path = path.delete_suffix(ext) if TEMPLATE_EXTENSIONS.include?(ext)
    return [path] unless File.basename(path) == "index.html"

    [path.delete_suffix("index.html"), path]
  end
end
