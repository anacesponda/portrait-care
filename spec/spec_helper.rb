# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
end

RSpec.configure do |config|
  config.around(:each) do |example|
    example.metadata[:vcr]
    if example.metadata[:vcr]
      vcr_options = example.metadata[:vcr]
      VCR.use_cassette(vcr_options[:cassette_name],
                       record: vcr_options[:record],
                       match_requests_on: vcr_options[:match_requests_on] || %i[
                         host path query
                       ]) do
        example.run
      end
    else
      example.run
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
