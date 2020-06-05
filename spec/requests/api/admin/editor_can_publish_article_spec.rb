RSpec.describe 'Api::Admin::Articles :update', type: :request do
  let!(:article) { create(:article, published: false) }
  let(:editor) { create(:user, role: 'editor') }
  let(:editors_credentials) { editor.create_new_auth_token }
  let(:editors_headers) { { HTTP_ACCEPT: 'application/json' }.merge!(editors_credentials) }

  let(:journalist) { create(:user, email: "asd@asd.com", role: 'journalist') }
  let(:journalist_credentials) { journalist.create_new_auth_token }
  let(:journalist_headers) { { HTTP_ACCEPT: 'application/json' }.merge!(journalist_credentials) }

  describe 'editor successfully updates and' do
    before do
      put "/api/admin/articles/#{article.id}", 
      headers: editors_headers, 
      params: { activity: "PUBLISH", premium: true , category: 'economy'}
      article.reload()
    end

    it 'gives a success code' do
      expect(response).to have_http_status 200
    end

    it 'gives a success message' do
      expect(response_json['message']).to eq "Article successfully published!"
    end

    it 'has set published to true' do
      expect(article.published).to eq true
    end

    it 'has set category to economy' do
      expect(article.category).to eq "economy"
    end

    it 'has set premium to true' do
      expect(article.premium).to eq true
    end
  end

  describe 'editor successfully updates only few params' do
    before do
      put "/api/admin/articles/#{article.id}", 
      headers: editors_headers, 
      params: { activity: "PUBLISH", category: 'economy'}
      article.reload()
    end

    it 'gives success status' do
      expect(response).to have_http_status 200
    end

    it 'updates the provided params' do
      expect(article.category).to eq 'economy'
    end

    it 'but not the not provided ones' do
      expect(article.premium).to eq false
    end
  end

  describe 'article with provided id does not exist' do
    before do
      put "/api/admin/articles/2000001", 
      headers: editors_headers, 
      params: { activity: "PUBLISH", premium: true , category: 'economy'}
      article.reload()
    end

    it 'gives an error code' do
      expect(response).to have_http_status 422
    end

    it 'gives an error message' do
      expect(response_json['message']).to eq "Article not published: Couldn't find Article with 'id'=2000001"
    end
  end

  describe 'with bad params' do
    before do
      put "/api/admin/articles/#{article.id}", 
      headers: editors_headers, params: 
      { activity: "PUBLISH", premium: false , category: 'music'}
      article.reload()
    end

    it 'gives an error code' do
      expect(response).to have_http_status 422
    end

    it 'gives an error message' do
      expect(response_json['message']).to eq "Article not published: 'music' is not a valid category"
    end

    it 'article was not published' do
      expect(article.published).to eq false
    end
  end

  describe 'journalist cannot update articles' do
    before do
      put "/api/admin/articles/#{article.id}", headers: journalist_headers, params: { activity: "PUBLISH", premium: true }
    end

    it 'has a 401 response' do
      expect(response).to have_http_status 401
    end

    it 'and an error message' do
      expect(response_json['errors'][0]).to eq "You are not authorized"
    end
  end

  describe 'visitors cannot update articles' do
    before do
      put "/api/admin/articles/#{article.id}", 
      params: { activity: "PUBLISH", 
      premium: true, category: 'economy' }
    end

    it 'has a 401 response' do
      expect(response).to have_http_status 401
    end

    it 'and an error message' do
      expect(response_json['errors'][0]).to eq "You need to sign in or sign up before continuing."
    end
  end
end