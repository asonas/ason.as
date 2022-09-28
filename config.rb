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
end

page "/articles", layout: "layout", directory_index: false
page "/articles/*", layout: "layout"

proxy("/articles", "articles/index.html", locals: { articles_from_config: Article.all }, ignore: true)
Article.all.each do |article|
  proxy(article.path, "articles/show.html", locals: { article: article }, ignore: true)
end
proxy("/feed", "feed.xml", locals: { articles_from_config: Article.all }, ignore: true)

activate :external_pipeline, {
  name: :webpack,
  command: build? ?
    "NODE_ENV=production npm run build" :
    "NODE_ENV=develop npm run develop",
  source: ".tmp/build",
  latency: 1
}

# helpers do
#   def some_helper
#     'Helping'
#   end
# end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

# configure :build do
#   activate :minify_css
#   activate :minify_javascript
# end
