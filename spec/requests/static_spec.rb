require 'rails_helper'

RSpec.describe "Root", type: :request do
  describe "GET /" do
    before do
      allow(DeveloperPortfoliosFetcher).to receive(:fetch).and_return([])
    end

    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
