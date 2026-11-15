# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

activate :livereload

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/
require './models/meta_tags'

helpers do
  # source/images/icons/ 配下のSVG(CC0: Simple Icons)をインライン展開する。
  # 色とサイズはCSS(.social-link svg)で制御する。リンク側のaria-labelと重複しないよう
  # aria-hidden を付与し、装飾要素として扱う。
  def inline_svg(name)
    path = File.expand_path("source/images/icons/#{name}.svg", __dir__)
    svg = File.read(path)
    svg.sub('<svg ', '<svg aria-hidden="true" focusable="false" ').html_safe
  end

  @@meta_tags = nil

  def display_meta_tags
    return nil if @@meta_tags.nil?

    html = MetaTags.render(@@meta_tags)
    @@meta_tags = nil
    html
  end

  def set_meta_tags(hash=nil)
    @@meta_tags = hash
  end

  def default_meta_tags
    {
      title: "ason.as",
      description: "I am asonas.",
      canonical: "https://ason.as/",
      og: {
        title: "ason.as",
        description: "I am asonas.",
        image: "https://ason.as/images/ogimage.png",
        url: :canonical,
        type: "website",
      },
      twitter: {
        title: "ason.as",
        description: "I am asonas.",
        site: "asonas",
        image: "https://ason.as/images/ogimage.png",
        card: "summary_large_image",
      },
    }
  end
end

# アイコンSVGは inline_svg ヘルパーでHTMLに直接埋め込むため、単体ファイルとしては配信しない。
ignore "images/icons/*.svg"

# CSS はブラウザに長期キャッシュさせるので、内容が変わったら URL も変わるようファイル名にハッシュを付ける
activate :asset_hash, exts: %w[.css]
