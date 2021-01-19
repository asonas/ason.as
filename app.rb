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
    haml :index
  end

  get '/articles' do
    @articles = Article.all
    haml :articles_index
  end

  get '/articles/:id' do
    @article = Article.find_by(params[:id])
    haml :articles_show
  end

  get '/feed', provides: ["rss", "xml", "atom"] do
    @articles = Article.all
    erb :feed
  end
end
