# frozen_string_literal: true

class Article::IndexSerializer < ActiveModel::Serializer
  attributes :page, :next_page, :articles

  def page
    object[:page]
  end

  def next_page
    object[:articles].length > 20 ? object[:page] + 1 : nil
  end

  def articles
    object[:articles][0...20].map do |article|
      Article::IndexEachSerializer.new(article).to_h
    end
  end
end
