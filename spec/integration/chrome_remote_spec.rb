require "spec_helper"
require "json"

RSpec.describe ChromeRemote do

  let(:mock_server) { WebServiceServerMock.new(host: '127.0.0.1', port: 9222) }

  after(:each) { mock_server.close }

  it "has a version number" do
    expect(ChromeRemote::VERSION).not_to be nil
  end

  it "sends commands using the DevTools protocol" do
    expected_result = { "frameId" => rand(9999) }

    mock_server.expect_message do |msg|
      msg = JSON.parse(msg)

      expect(msg["method"]).to eq("Page.navigate")
      expect(msg["params"]).to eq("url" => "https://github.com")
      expect(msg["id"]).to be_a(Integer)

      # Reply with two messages not correlating the msg["id"].
      # These two should be ignored by the client
      mock_server.send_message({ method: "RandomEvent" }.to_json)
      mock_server.send_message({ id: 9999, result: {} }.to_json)

      # Reply correlated with msg["id"]
      mock_server.send_message({ id: msg["id"], 
                                 result: expected_result }.to_json)
    end

    chrome = ChromeRemote.client

    response = chrome.send_cmd "Page.navigate", url: "https://github.com"

    expect(response).to eq(expected_result)
    expect(mock_server).to have_satisfied_all_expectations
  end
end
