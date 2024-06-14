# frozen_string_literal: true

module Api
  module V1
    # Controller for stocks
    class StocksController < ApplicationController
      def statistics
        response = ::ApiClients::PolygonApi.connection.get(url) do |req|
          req.params["apiKey"] = api_key
        end

        if response.success?
          data = JSON.parse(response.body)
          if data["queryCount"].to_i > 0
            results = process_data(data["results"])
            render json: results
          else
            render json: { error: "No data available" }, status: :bad_request
          end
        else
          render json: { error: "Failed to fetch data" }, status: :bad_request
        end
      end

      private

      def process_data(data)
        initialize_aggregated_data

        aggregated_data = initialize_aggregated_data
        data.each do |result|
          # todo; read max and min values to calculate min and max properly.
          price = result["c"]
          volume = result["v"]
          update_aggregated_data(aggregated_data, price, volume)
        end
        compute_final_aggregates(aggregated_data, data.length)
      end

      # TODO: check if we are defining the aggregated data correctly
      def initialize_aggregated_data
        {
          total_price: 0,
          total_volume: 0,
          max_volume: -Float::INFINITY,
          min_volume: Float::INFINITY,
          max_price: -Float::INFINITY,
          min_price: Float::INFINITY
        }
      end

      def update_aggregated_data(aggregated_data, price, volume)
        aggregated_data[:total_price] += price
        aggregated_data[:total_volume] += volume
        aggregated_data[:max_volume] = [aggregated_data[:max_volume], volume].max
        aggregated_data[:min_volume] = [aggregated_data[:min_volume], volume].min
        aggregated_data[:max_price] = [aggregated_data[:max_price], price].max
        aggregated_data[:min_price] = [aggregated_data[:min_price], price].min
      end

      # Todo: I think there's a an error of how I'm calculating the average_price
      # lowest price and High price should be consider.
      def compute_final_aggregates(aggregated_data, result_count)
        {
          average_price: aggregated_data[:total_price] / result_count,
          average_volume: aggregated_data[:total_volume] / result_count,
          max_volume: aggregated_data[:max_volume],
          min_volume: aggregated_data[:min_volume],
          max_price: aggregated_data[:max_price],
          min_price: aggregated_data[:min_price]
        }
      end

      def url
        "/v2/aggs/ticker/#{ticker}/range/#{range}/#{start_date}/#{end_date}"
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
