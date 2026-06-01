require "json"
require "fileutils"

# embed メタデータのローカルファイルキャッシュ。
# S3 (BUCKET_NAME) が使えない開発環境で、MetaInspector のライブ取得結果を
# ローカルに永続化し、リロードのたびに再取得しないようにする。
class EmbedCache
  def initialize(dir)
    @dir = dir
  end

  def fetch(key)
    path = path_for(key)
    return JSON.parse(File.read(path)) if File.exist?(path)

    value = yield
    FileUtils.mkdir_p(@dir)
    File.write(path, JSON.generate(value))
    value
  end

  private

  def path_for(key)
    File.join(@dir, "#{key}.json")
  end
end
