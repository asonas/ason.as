require 'redcarpet'
require 'html/pipeline'
require 'yaml'
require 'pry'
class Article
  def self.all
    r = []
    Dir.glob("./articles/*.md").sort.reverse.each do |a|
      id = File.basename(a, ".md")
      r.push find_by(id)
    end

    r
  end

  def self.recent
    r = []
    Dir.glob("./articles/*.md").sort.reverse.take(5).each do |a|
      id = File.basename(a, ".md")
      r.push find_by(id)
    end

    r
  end

  def self.find_by(id)
    path = "articles/#{id}.md"
    if File.exists? path
      new(id, File.read(path), File.mtime(path))
    end
  end

  attr_accessor :title, :body, :date, :raw_content, :path, :updated_at

  def initialize(id, raw_content, updated_at)
    @raw_content = raw_content
    @title = title
    @body = body
    @date = date
    @path = "/articles/#{id}"
    @updated_at = updated_at
  end

  def title
    @title = meta['title']
  end

  def body
    contents[:body]
  end

  def body_only_text
    doc = Nokogiri::HTML.parse(self.rendered_body)
    doc.text
  end

  def summary
    body[0..100] + "..."
  end

  def url
    "https://www.ason.as#{path}"
  end

  def published_at
    date.rfc822
  end

  def created_at
    date
  end

  def date
    meta['date']
  end

  def rendered_body
    pipeline = HTML::Pipeline.new(
      [

        MarkdownFilter,
        BlockquotesFilter,
        ImageTagFilter,
      ]
    )
    result = pipeline.call(body)
    result[:output].to_s
  end

  def meta
    contents[:meta]
  end

  def contents
    array = @raw_content.split("---\n", 3)
    {
      body: array[2],
      meta: YAML.load(array[1])
    }
  end

  class MarkdownFilter < HTML::Pipeline::TextFilter
    def call
      markdown = Redcarpet::Markdown.new(
        Redcarpet::Render::HTML,
        autolink: true,
        fenced_code_blocks: true,
        no_intra_emphasis: true
      )
      res = markdown.render(@text)
      Nokogiri::HTML.fragment(res)
    end
  end

  class BlockquotesFilter < HTML::Pipeline::Filter
    def call
      doc.search('blockquote').each do |e|
        next if e.attributes["class"]&.value == "twitter-tweet"
        e[:class] = "blockquote"
        e.children.search('p').each do |d|
          d[:class] = "mb-0"
        end
      end

      doc
    end
  end

  class ImageTagFilter < HTML::Pipeline::Filter
    def call
      doc.search('img').each do |img|
        img[:src] = img[:src].gsub(/^\/static/, "")
        img[:class] = "img-fluid"
      end

      doc
    end
  end
end
