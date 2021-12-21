require 'sinatra/base'
require 'sinatra/static_assets'
require "sinatra/reloader"
require 'pry'
require "./models/article"

class Asns < Sinatra::Base
  set :static, true
  set :public_folder, __dir__ + '/static'

  get '/' do
    @articles = Article.recent
    @title = "ason.as"
    @description = "@asonasのブログ"
    @url = "https://www.ason.as/"
    @image = "https://www.ason.as/images/ogpimage.png"
    haml :index
  end

  get '/articles' do
    @articles = Article.all
    @title = "ason.as | Articles"
    @description = "@asonasのブログ"
    @url = "https://www.ason.as/articles"
    @image = "https://www.ason.as/images/ogpimage.png"

    haml :articles_index
  end

  get '/articles/:id' do
    @article = Article.find_by(params[:id])
    @title = "ason.as | #{@article.title}"
    @description = @article.body_only_text[0..100] + "..."
    @url = @article.url
    @image = "https://www.ason.as/images/ogpimage.png"

    haml :articles_show
  end

  get '/feed', provides: ["rss", "xml", "atom"] do
    @articles = Article.all
    erb :feed
  end
end
