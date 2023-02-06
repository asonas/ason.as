# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

set :haml, format: :html5

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

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
      }
    }
  end
end

page "/articles", layout: "layout"
page "/articles/*", layout: "layout"

Article.all.each do |article|
  proxy(article.path, "articles/show.html", locals: { article: article }, ignore: true)
end
proxy("/feed", "feed.xml", locals: { articles_from_config: Article.all }, ignore: true)
proxy("/.well-known/nostr.json", "nostr.json")

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
