# frozen_string_literal: true

RSpec.describe 'Api::Articles :index', type: :request do
  categories = Article.categories.keys
  categories.each do |category|
    let!("#{category}_articles".to_sym) { 4.times { create(:article, category: category) } }
  end
  let!(:extra_swedish_sport_articles) { 7.times { create(:article, location: 'Sweden', international: false )}}
  let!(:extra_swedish_international_sport_articles) { 9.times { create(:article, location: 'Sweden', international: true, published_at: Time.now - 5.days )}}
  let!(:extra_international_sport_articles) { 11.times { create(:article, location: nil, international: true )}}
  let!(:unpublished_articles) { 3.times { create(:article, published: false) } }
  
  describe 'GET /api/articles without any params' do
    before do
      get '/api/articles'
    end
    
    it 'has a 200 response' do
      expect(response).to have_http_status 200
    end

    it 'returns first page of articles' do
      expect(response_json['page']).to eq 1
    end

    it 'returns index of next page' do
      expect(response_json['next_page']).to eq 2
    end

    it 'returns one batch of 20 of the latest international articles' do
      expect(response_json['articles'].length).to eq 20
    end

    it 'returns only published articles' do
      response_json['articles'].each do |article|
        expect(article['published_at']).not_to eq nil
      end
    end

    it 'returns only international articles' do
      response_json['articles'].each do |article|
        expect(article['international']).to eq true
      end
    end

    describe 'response has keys' do
      it ':title' do
        expect(response_json['articles'][0]).to have_key 'title'
      end

      it ':category' do
        expect(response_json['articles'][0]).to have_key 'category'
      end

      it ':published_at' do
        expect(response_json['articles'][0]).to have_key 'published_at'
      end

      it ':location' do
        expect(response_json['articles'][0]).to have_key 'location'
      end

      it ':international' do
        expect(response_json['articles'][0]).to have_key 'international'
      end
    end

    describe 'response does not have keys' do
      it ':updated_at' do
        expect(response_json['articles'][0]).not_to have_key 'updated_at'
      end

      it 'created_at' do
        expect(response_json['articles'][0]).not_to have_key 'created_at'
      end
    end
  end

  describe 'GET /api/articles with params...' do
    it 'page, location (51 items)' do
      get '/api/articles', params: { location: 'Sweden', page: 3 }
      expect(response_json['articles'].length).to eq 11
    end
    
    it 'page, category  (24 items)' do
      get '/api/articles', params: { category: 'sport', page: 2 }
      expect(response_json['articles'].length).to eq 4
    end

    it 'page, location, category (31 items)' do
      get '/api/articles', params: { category: 'sport', location: 'Sweden', page: 2 }
      expect(response_json['articles'].length).to eq 11
    end

    it 'category: current (35 items)' do
      get '/api/articles', params: { category: 'current', page: 2 }
      expect(response_json['articles'].length).to eq 15
    end

    it 'category: local (16 items)' do
      get '/api/articles', params: { category: 'local', location: 'Sweden' }
      expect(response_json['articles'].length).to eq 16
    end
  end

  describe 'GET /api/articles tells you if there is more content' do
    it 'tells you there is another page to fetch' do
      get '/api/articles', params: { category: 'sport' }
      expect(response_json['next_page']).to eq 2
    end

    it 'tells you there is not another page to fetch' do
      get '/api/articles', params: { category: 'sport', page: 2 }
      expect(response_json['next_page']).to eq nil
    end
  end
end
