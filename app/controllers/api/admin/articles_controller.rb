# frozen_string_literal: true

class Api::Admin::ArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :editor?

  def index
    article = Article.where(published: false)
    render json: article, each_serializer: Admin::Article::IndexSerializer
  end

  def show
    article = Article.find(params[:id])
    if article.published == true
      render json: { message: 'This article was already published' }, status: 400
    else
      render json: article, serializer: Admin::Article::ShowSerializer
    end
  rescue StandardError => e
    render json: { message: e.message }, status: 404
  end

  def update
    if params[:activity] == "PUBLISH"
      begin
        article = Article.find(params[:id])
        article.premium = params[:premium] || article.premium
        article.category = params[:category] || article.category
        article.published = true
        article.save
        render json: { message: 'Article successfully published!'}
      rescue => error
        render json: { message: "Article not published: " + error.message }, status: 422
      end
    end
  end

  private

  def editor?
    unless current_user.role == 'editor'
      render json: { message: 'You are not authorized', errors: ['You are not authorized'] }, status: 401
    end
  end
end
