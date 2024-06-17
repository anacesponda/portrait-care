require 'rails_helper'

RSpec.describe Api::V1::StocksController, type: :controller do
  describe "GET #statistics" do
    context "with a valid ticker", vcr: { cassette_name: 'statistics_valid_ticker', record: :once } do
      it "returns the statistics correctly" do
        get :statistics, params: { ticker: 'AAPL' }

        expected_response = {
          average_price: 172.41940240000005,
          average_volume: 59153887.104,
          max_volume: 154338835.0,
          min_volume: 24018404.0,
          max_price: 199.62,
          min_price: 124.17,
        }.stringify_keys

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to eq(expected_response)
      end
    end

    context "with an invalid ticker", vcr: { cassette_name: 'statistics_invalid_ticker', record: :once } do
      it "returns an error" do
        get :statistics, params: { ticker: 'INVALID' }

        expected_response = { error: "No data available" }.stringify_keys

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq(expected_response)
      end
    end
  end
end
