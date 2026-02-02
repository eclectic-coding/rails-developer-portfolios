require 'rails_helper'

# Request spec for the developer portfolios root path
RSpec.describe "Developer portfolios root", type: :request do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
