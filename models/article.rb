require 'aws-sdk-s3'
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
    if File.exist? path
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

  def image_url
    doc = Nokogiri::HTML self.rendered_body
    img = doc.css("img").first

    if ogp_image
      "https://ason.as/" + ogp_image
    elsif img
      "https://ason.as" + img.attributes["src"].value
    else
      "https://ason.as/images/ogimage.png"
    end
  end

  def ogp_image
    meta['ogp_image']
  end

  def leadline
    body_only_text.split("\n").compact.reject(&:empty?).join(" ")[0...60] + "..."
  end

  def body_only_text
    doc = Nokogiri::HTML.parse(self.rendered_body)
    doc.text
  end

  def summary
    body[0..100] + "..."
  end

  def url
    "https://ason.as#{path}"
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
        EmbedTagFilter,
        MarkdownFilter,
        BlockquotesFilter,
        ImageTagFilter,
      ]
    )
    result = pipeline.call(body)
    result[:output].to_s
  end

  def to_meta_tags
    {
      title: title,
      description: leadline,
      canonical: url,
      og: {
        title: title,
        description: leadline,
        image: image_url,
        url: url,
        type: "website",
      },
      twitter: {
        title: title,
        description: leadline,
        site: "@asonas",
        image: image_url,
        card: "summary_large_image",
      },
    }
  end

  def meta
    contents[:meta]
  end

  def contents
    array = @raw_content.split("---\n", 3)
    {
      body: array[2],
      meta: YAML.safe_load(array[1], permitted_classes: [Time]),
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

  # markdown => html
  # syntax e.g. `[embed:https://example.com/foo-bar]`
  class EmbedTagFilter < HTML::Pipeline::TextFilter
    REGEX = %r!\[embed:(https?:\/\/[\w\/:%#\$&\?\(\)~\.=\+\-]+)\]!
    BUCKET_NAME = ENV["BUCKET_NAME"]
    attr_accessor :url, :response, :client

    def call
      @client = Aws::S3::Client.new(region: "ap-northeast-1")
      @text.match REGEX
      @url = $1
      if @url
        fetch_meta_from_cache
        render
      end

      @text
    end

    def render
      b = binding
      erb = ERB.new <<~EOF
      <div class="embed">
        <a href="<%= response["url"] %>">
          <img src="<%= response["images"].first %>">
          <div class="body">
            <header><%= response["title"] %></header>
            <div>
              <p><%= response["description"] %></p>
            </div>
          </div>
        </a>
      </div>
      EOF
      @text.gsub!(REGEX, erb.result(b))
    end

    def fetch_meta_from_cache
      object = client.get_object(bucket: BUCKET_NAME, key: "jsonlink-io/#{cache_filename}")
      @response = JSON.parse(object.body.read)
    rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::AccessDenied => e
      fetch_meta
      save_cache
    end

    def fetch_meta
      @response = JSON.parse(
        Net::HTTP.get(
          URI.parse("https://jsonlink.io/api/extract?url=#{@url}")
        )
      )
    end

    def save_cache
      client.put_object(bucket: BUCKET_NAME, key: "jsonlink-io/#{cache_filename}", body: response.to_json)
    end

    def cache_filename
      Digest::SHA256.hexdigest @url
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
        img[:src] = img[:src].gsub(/^..\/source/, "")
        img[:class] = "img-fluid"
      end

      doc
    end
  end
end
