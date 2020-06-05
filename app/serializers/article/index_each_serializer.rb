# frozen_string_literal: true

class Article::IndexEachSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :title, :category, :published_at, :image, :location, :international

  def published_at
    object.published_at.strftime('%F %R')
  end

  def image
    return nil unless object.image.attached?

    if Rails.env.test?
      rails_blob_url(object.image)
    else
      object.image.service_url(expires_in: 1.hour, disposition: 'inline')
    end
  end
end
