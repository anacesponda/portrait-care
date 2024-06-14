# frozen_string_literal: true

module ApiClients
  # Faraday connection for polygon api
  class PolygonApi
    def self.connection
      Faraday.new(url: "https://api.polygon.io") do |faraday|
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter Faraday.default_adapter   # make requests with Net::HTTP
      end
    end
  end
end
