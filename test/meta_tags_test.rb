require "minitest/autorun"
require_relative "../models/meta_tags"

class MetaTagsTest < Minitest::Test
  def render(tags)
    MetaTags.render(tags)
  end

  # 標準のdescriptionは name="description" で出力する（property= ではGoogleが認識しない）
  def test_description_uses_name_attribute
    html = render(description: "I am asonas.")
    assert_includes html, %(<meta name="description" content="I am asonas." />)
    refute_includes html, %(property="description")
  end

  # canonicalは <link rel="canonical"> で出力する（meta property ではない）
  def test_canonical_is_rendered_as_link
    html = render(canonical: "https://ason.as/")
    assert_includes html, %(<link rel="canonical" href="https://ason.as/" />)
    refute_includes html, %(<meta property="canonical")
  end

  # OGPは property= で出力する
  def test_og_uses_property_attribute
    html = render(og: { title: "ason.as", type: "website" })
    assert_includes html, %(<meta property="og:title" content="ason.as" />)
    assert_includes html, %(<meta property="og:type" content="website" />)
  end

  # og:url に :canonical シンボルが指定された場合は canonical のURLへ解決する
  def test_og_url_resolves_canonical_symbol
    html = render(canonical: "https://ason.as/", og: { url: :canonical })
    assert_includes html, %(<meta property="og:url" content="https://ason.as/" />)
    refute_includes html, %(content="canonical")
  end

  # Twitterカードは name= で出力する（Twitterの仕様）
  def test_twitter_uses_name_attribute
    html = render(twitter: { card: "summary_large_image" })
    assert_includes html, %(<meta name="twitter:card" content="summary_large_image" />)
  end

  # title要素は別途あるため meta title は出力しない
  def test_title_is_not_rendered_as_meta
    html = render(title: "ason.as")
    refute_includes html, %(content="ason.as")
  end

  # HTMLとして危険な文字はエスケープする
  def test_escapes_html_special_characters
    html = render(description: %(a & b "<c>"))
    assert_includes html, "a &amp; b"
    refute_includes html, "<c>"
  end

  # nilを渡しても空文字列を返す
  def test_nil_returns_empty_string
    assert_equal "", render(nil)
  end
end
