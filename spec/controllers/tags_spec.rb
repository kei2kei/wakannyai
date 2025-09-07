
require 'rails_helper'

RSpec.describe TagsController, type: :controller do
  let(:user) { create(:user) }
  let!(:tag1) { create(:tag, name: 'ruby') }
  let!(:tag2) { create(:tag, name: 'rails') }
  let!(:tag3) { create(:tag, name: 'ruby_on_rails') }
  let!(:tag4) { create(:tag, name: 'javascript') }

  describe 'GET #search' do
    before { sign_in user }

    context 'クエリが存在する場合' do
      it 'クエリに一致するタグをJSON形式で返す' do
        get :search, params: { query: 'ru' }, format: :json
        parsed_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(parsed_body.map { |t| t['value'] }).to match_array(['ruby', 'ruby_on_rails'])
      end

      it 'クエリに一致するタグがない場合、空の配列を返す' do
        get :search, params: { query: 'python' }, format: :json
        parsed_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(parsed_body).to be_empty
      end
    end

    context 'クエリが存在しない場合' do
      it '空の配列を返す' do
        get :search, params: { query: '' }, format: :json
        parsed_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(parsed_body).to be_empty
      end
    end
  end
end
