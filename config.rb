# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

set :haml, format: :html5, escape_html: false

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
require './models/article'

helpers do
  def articles
    Article.all
  end

  @@meta_tags = nil

  def display_meta_tags
    return nil if @@meta_tags.nil?

    metas = []
    @@meta_tags.each do |k, v|
      case k
      when :twitter
        v.each do |prop, v|
          metas.push generate_meta_tag(prop, v, "twitter")
        end
      when :og
        v.each do |prop, v|
          metas.push generate_meta_tag(prop, v, "og")
        end
      else
        metas.push generate_meta_tag(k, v)
      end
    end

    @@meta_tags = nil
    metas.join
  end

  def generate_meta_tag(prop, content, parent=nil)
    property =
      if parent
        "#{parent}:#{prop}"
      else
        prop
      end
    tag(:meta, property: property, content: content)
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

page "/articles", layout: "layout"
page "/articles/*", layout: "layout"

# show.html.haml は ArticleSitemap が proxy のテンプレートとして使うだけ。
# 直接ビルドされると article_id が未定義になるので除外する。
ignore "articles/show.html"

# 記事Markdownは source/ の外にあるが、開発時はファイル変更を sitemap rebuild に
# 伝搬させたいので watcher に登録する。auto-discoverされた .md は下の
# ArticleSitemap extension で除外し、proxy 経由でのみ配信する。
files.watch :source, path: File.expand_path("articles", __dir__)

# articles/*.md を毎回 sitemap rebuild 時に再スキャンして proxy 化する。
# これにより記事の追加・削除・本文変更がサーバ再起動なしで反映される。
class ArticleSitemap < Middleman::Extension
  def manipulate_resource_list(resources)
    articles_root = File.expand_path("articles", @app.root)
    prefix = articles_root + File::SEPARATOR

    filtered = resources.reject do |r|
      r.source_file && r.source_file.start_with?(prefix)
    end

    Dir.glob(File.join(articles_root, "*.md")).each do |path|
      id = File.basename(path, ".md")
      resource = Middleman::Sitemap::ProxyResource.new(
        @app.sitemap, "articles/#{id}", "articles/show.html"
      )
      resource.add_metadata(locals: { article_id: id }, options: { layout: "layout" })
      filtered << resource
    end

    filtered
  end
end
Middleman::Extensions.register(:article_sitemap, ArticleSitemap)
activate :article_sitemap

proxy("/feed", "feed.xml", ignore: true)

cmd =
  if build?
    "NODE_ENV=production npm run build"
  else
    "NODE_ENV=develop npm run develop"
  end
activate :external_pipeline, {
  name: :webpack,
  command: cmd,
  source: "build",
  latency: 1,
}
