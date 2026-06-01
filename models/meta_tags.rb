require "cgi"

# <head> に挿入するメタタグ群をハッシュからHTML文字列へ描画する。
#
# 属性の使い分けは検索エンジン・各SNSの仕様に合わせる:
#   - 標準メタ(description等) は name=
#   - OGP(og:*)              は property=
#   - Twitterカード(twitter:*) は name=
#   - canonical              は <link rel="canonical">
#
# og:url 等に :canonical シンボルが入っている場合は、トップレベルの canonical URL へ解決する。
module MetaTags
  module_function

  def render(tags)
    return "" if tags.nil?

    canonical = tags[:canonical]

    tags.filter_map { |key, value| render_entry(key, value, canonical) }.join
  end

  def render_entry(key, value, canonical)
    case key
    when :canonical
      link_tag("canonical", value)
    when :og
      render_group(value, "og", :property, canonical)
    when :twitter
      render_group(value, "twitter", :name, canonical)
    when :title
      # <title> 要素が別途存在するため meta title は出力しない
      nil
    else
      meta_tag(key, value, :name)
    end
  end

  def render_group(group, prefix, attr, canonical)
    group
      .map { |prop, value| meta_tag("#{prefix}:#{prop}", resolve(value, canonical), attr) }
      .join
  end

  def resolve(value, canonical)
    value == :canonical ? canonical : value
  end

  def meta_tag(name, content, attr)
    %(<meta #{attr}="#{escape(name)}" content="#{escape(content)}" />)
  end

  def link_tag(rel, href)
    %(<link rel="#{escape(rel)}" href="#{escape(href)}" />)
  end

  def escape(value)
    CGI.escapeHTML(value.to_s)
  end
end
