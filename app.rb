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

  get '/articles/:id' do
    @article = Article.find_by(params[:id])
    haml :show
  end
end
