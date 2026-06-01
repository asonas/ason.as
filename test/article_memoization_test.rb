require "minitest/autorun"
require_relative "../models/article"

class ArticleMemoizationTest < Minitest::Test
  # embed を含まない記事（ネットワークアクセスを伴わない）
  RAW = <<~MD
    ---
    title: Test Article
    date: 2020-01-01 00:00:00 +0900
    ---
    # Hello

    本文のテキストです。
  MD

  def build_article(klass = Article)
    klass.new("2020-01-01-test", RAW, Time.now)
  end

  def test_contents_is_memoized
    art = build_article
    assert_same art.contents, art.contents
  end

  def test_rendered_body_is_memoized
    art = build_article
    assert_same art.rendered_body, art.rendered_body
  end

  def test_leadline_and_image_url_do_not_rebuild_rendered_body
    counting = Class.new(Article) do
      attr_reader :build_count

      def build_rendered_body
        @build_count = (@build_count || 0) + 1
        super
      end
    end

    art = build_article(counting)
    art.leadline
    art.image_url
    art.rendered_body

    assert_equal 1, art.build_count,
      "rendered_body should be built once even when leadline/image_url/rendered_body are all called"
  end
end
