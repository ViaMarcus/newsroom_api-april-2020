# frozen_string_literal: true

class Api::ArticlesController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  def index
    page = params[:page] || 1
    category = params[:category] || 'all'
    location = params[:location]
    offset = (page.to_i - 1) * 20

    case category
    when 'local'
      articles = Article
                 .where(location: location, published: true)
                 .order('published_at DESC')
                 .limit(21)
                 .offset(offset)
    when 'current'
      last_24hrs = Time.now - 1.day..Time.now
      articles = Article
                 .where(location: location, published_at: last_24hrs, published: true)
                 .or(Article.where(international: true, published_at: last_24hrs, published: true))
                 .order('published_at DESC')
                 .limit(21)
                 .offset(offset)
    when 'all'
      articles = Article
                 .where(location: location, published: true)
                 .or(Article.where(international: true, published: true))
                 .order('published_at DESC')
                 .limit(21)
                 .offset(offset)
    else
      articles = Article
                 .where(category: category, location: location, published: true)
                 .or(Article.where(category: category, international: true, published: true))
                 .order('published_at DESC')
                 .limit(21)
                 .offset(offset)
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
    Article
      .where(location: location, published: true, *first_params )
      .or(Article.where(international: true, published: true,*or_params))
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
