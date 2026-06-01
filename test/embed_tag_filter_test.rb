require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../models/article"

class EmbedTagFilterTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # local_cache_dir をテスト用の一時ディレクトリに差し替え、
  # fetch_meta（ライブ取得）の呼び出し回数を数えるテスト用フィルタ。
  def filter_class(dir)
    Class.new(Article::EmbedTagFilter) do
      attr_reader :fetch_count
      define_method(:local_cache_dir) { dir }

      def fetch_meta
        @fetch_count = (@fetch_count || 0) + 1
        @response = { "url" => @url, "title" => "stub", "description" => "d", "images" => [] }
      end
    end
  end

  def test_fetch_meta_from_cache_uses_local_cache_when_s3_unavailable
    klass = filter_class(@dir)
    url = "https://example.com/page"

    first = klass.new
    first.instance_variable_set(:@url, url)
    first.instance_variable_set(:@is_youtube, false)
    first.fetch_meta_from_cache
    assert_equal 1, first.fetch_count

    # 別インスタンス・同じキャッシュディレクトリ。ライブfetchは走らないはず。
    second = klass.new
    second.instance_variable_set(:@url, url)
    second.instance_variable_set(:@is_youtube, false)
    second.fetch_meta_from_cache
    assert_nil second.fetch_count, "second call must hit the local cache and skip fetch_meta"
    assert_equal "stub", second.response["title"]
  end

  def test_call_does_not_create_s3_client_when_no_embeds
    f = Article::EmbedTagFilter.new
    f.call("ここには embed タグはありません")
    assert_nil f.client, "no S3 client should be created when there is no embed tag"
  end
end
