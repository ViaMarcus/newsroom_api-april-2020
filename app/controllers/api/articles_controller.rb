# frozen_string_literal: true

class Api::ArticlesController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  def index
    category = params[:category] || 'all'
    page = params[:page] || 1
    case category
    when 'local'
      articles = find_articles({}, { id: -1 })
    when 'current'
      last_24hrs = Time.now - 1.day..Time.now
      articles = find_articles({ published_at: last_24hrs },{ published_at: last_24hrs })
    when 'all'
      articles = find_articles({},{})
    else
      articles = find_articles({ category: category }, { category: category })
    end
    render json: Article::IndexSerializer.new({ :articles => articles, :page => page }).to_h
  end

  def show
    article = Article.find(params[:id])
    raise StandardError unless article.published

    render json: article, serializer: Article::ShowSerializer
  rescue StandardError
    render json: { message: "Article with id #{params[:id]} could not be found." }, status: :not_found
  end

  def create
    article = Article.create(article_params)
    if article.persisted? && attach_image(article)
      render json: { id: article.id, message: 'Article successfully created!' }
    elsif !attach_image(article)
      render json: { message: "Image can't be blank" }, status: 400
    else
      error = "#{article.errors.first[0].to_s.capitalize} #{article.errors.first[1]}"
      render json: { message: error }, status: 400
    end
  end

  private

  def find_articles(first_params, or_params)
    page = params[:page] || 1
    offset = (page.to_i - 1) * 20
    Article
      .where(location: params[:location], published: true, **first_params)
      .or(Article.where(international: true, published: true, **or_params))
      .order('published_at DESC')
      .limit(21)
      .offset(offset)
  end

  def attach_image(article)
    params_image = params[:image]
    if params_image.present?
      DecodeService.attach_image(params_image, article.image)
    end
  end

  def article_params
    params.permit(:title, :body, :category)
  end
end
