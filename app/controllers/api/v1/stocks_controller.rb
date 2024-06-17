# frozen_string_literal: true

module Api
  module V1
    # Controller for stocks
    class StocksController < ApplicationController
      def statistics
        response = fetch_api

        unless response.success?
          return render json: { error: "Failed to fetch data" }, status: :bad_request
        end

        data = JSON.parse(response.body)
        if data["queryCount"].to_i.positive?
          render json: process_data(data["results"])
        else
          render json: { error: "No data available" }, status: :bad_request
        end
      end

      private

      def fetch_api
        url = "/v2/aggs/ticker/#{ticker}/range/#{range}/#{start_date}/#{end_date}"
        ::ApiClients::PolygonApi.connection.get(url) { |req| req.params["apiKey"] = api_key }
      end

      def process_data(data)
        initialize_aggregated_data

        aggregated_data = initialize_aggregated_data
        data.each do |result|
          high_price = result["h"]
          low_price = result["l"]
          volume = result["v"]
          (high_price + low_price) / 2.0
          update_aggregated_data(aggregated_data, high_price, low_price, volume)
        end
        compute_final_aggregates(aggregated_data, data.length)
      end

      def initialize_aggregated_data
        {
          sum_daily_averages: 0,
          total_volume: 0,
          max_volume: -Float::INFINITY,
          min_volume: Float::INFINITY,
          max_price: -Float::INFINITY,
          min_price: Float::INFINITY
        }
      end

      def update_aggregated_data(aggregated_data, high_price, low_price, volume)
        update_volume(aggregated_data, volume)
        update_price_info(aggregated_data, high_price, low_price)
      end

      def update_volume(aggregated_data, volume)
        aggregated_data[:total_volume] += volume
        aggregated_data[:max_volume] = [aggregated_data[:max_volume], volume].max
        aggregated_data[:min_volume] = [aggregated_data[:min_volume], volume].min
      end

      def update_price_info(aggregated_data, high_price, low_price)
        aggregated_data[:sum_daily_averages] += (high_price + low_price) / 2
        aggregated_data[:max_price] = [aggregated_data[:max_price], high_price].max
        aggregated_data[:min_price] = [aggregated_data[:min_price], low_price].min
      end

      def compute_final_aggregates(aggregated_data, result_count)
        {
          average_price: aggregated_data[:sum_daily_averages] / result_count,
          average_volume: aggregated_data[:total_volume] / result_count,
          max_volume: aggregated_data[:max_volume],
          min_volume: aggregated_data[:min_volume],
          max_price: aggregated_data[:max_price],
          min_price: aggregated_data[:min_price]
        }
      end

      def ticker
        params[:ticker] || "AAPL"
      end

      def api_key
        ENV.fetch("POLYGON_API_KEY", nil)
      end

      def start_date
        params[:start_date] || "2023-01-01"
      end

      def end_date
        params[:end_date] || "2023-12-31"
      end

      def range
        params[:range] || "1/day"
      end
    end
  end
end
