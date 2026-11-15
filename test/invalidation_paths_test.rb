require "minitest/autorun"
require_relative "../models/invalidation_paths"

class InvalidationPathsTest < Minitest::Test
  # ディレクトリURLで配信するページは、テンプレート名ではなく末尾スラッシュのURLを無効化する
  def test_directory_index_template_maps_to_served_urls
    assert_equal ["/komado/policy/", "/komado/policy/index.html"],
      InvalidationPaths.for_file("source/komado/policy/index.html.haml")
  end

  # site.css に束ねられない独立したCSSは、それ自身のURLを無効化する
  def test_standalone_stylesheet_is_not_mapped_to_site_css
    assert_equal ["/stylesheets/yorumimizuku.css"],
      InvalidationPaths.for_file("source/stylesheets/yorumimizuku.css")
    assert_equal ["/stylesheets/site.css"],
      InvalidationPaths.for_file("source/stylesheets/syntax-highlight.css")
  end

  # 移行した記事の一覧が変わると旧 URL のリダイレクトが置き直されるため、記事の URL 全体を無効化する
  def test_moved_articles_list_invalidates_article_redirects
    assert_equal ["/articles", "/articles/*"], InvalidationPaths.for_file("moved_articles.txt")
    assert_empty InvalidationPaths.for_file("CLAUDE.md")
  end

  # アイコンSVGは単体配信せずレイアウトへ埋め込むため、SVGのURLではなく全ページを無効化する
  def test_inline_icon_invalidates_all_pages
    assert_equal ["/*"], InvalidationPaths.for_files(["source/images/icons/github.svg"])
  end
end
