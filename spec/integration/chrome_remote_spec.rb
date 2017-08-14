require "spec_helper"
require "json"

RSpec.describe ChromeRemote do

  subject { ChromeRemote.client }

  let!(:server) { WebSocketTestServer.new("ws://127.0.0.1:9222/ws?active=true") }

  after(:each) { server.close }

  it "sends commands using the DevTools protocol" do
    expected_result = { "frameId" => rand(9999) }

    server.expect_msg do |msg|
      msg = JSON.parse(msg)

      expect(msg["method"]).to eq("Page.navigate")
      expect(msg["params"]).to eq("url" => "https://github.com")
      expect(msg["id"]).to be_a(Integer)

      # Reply with two messages not correlating the msg["id"].
      # These two should be ignored by the client
      server.send_msg({ method: "RandomEvent" }.to_json)
      server.send_msg({ id: 9999, result: {} }.to_json)

      # Reply correlated with msg["id"]
      server.send_msg({ id: msg["id"], 
                        result: expected_result }.to_json)
    end

    response = with_timeout do
      subject.send_cmd "Page.navigate", url: "https://github.com"
    end

    expect(response).to eq(expected_result)
    expect(server).to have_satisfied_all_expectations
  end

  it "subscribes to events using the DevTools protocol" do
    received_events = []

    subject.on "Network.requestWillBeSent" do |params|
      received_events << ["Network.requestWillBeSent", params]
    end

    subject.on "Page.loadEventFired" do |params|
      received_events << ["Page.loadEventFired", params]
    end

    server.send_msg({ method: "RandomEvent" }.to_json)
    server.send_msg({ method: "Network.requestWillBeSent", params: { "param" => 1} }.to_json)
    server.send_msg({ id: 999, result: { "frameId" => 2 } }.to_json)
    server.send_msg({ method: "Page.loadEventFired",       params: { "param" => 2} }.to_json)
    server.send_msg({ method: "Network.requestWillBeSent", params: { "param" => 3} }.to_json)

    with_timeout do
      subject.listen_until { received_events.size == 3 }
    end

    expect(received_events).to eq([
      ["Network.requestWillBeSent", { "param" => 1}],
      ["Page.loadEventFired",       { "param" => 2}],
      ["Network.requestWillBeSent", { "param" => 3}],
    ])
  end

  it "allows to subscribe multiple times to the same event" do
    received_events = []
    
    subject.on "Network.requestWillBeSent" do |params|
      received_events << :first_handler
    end

    subject.on "Network.requestWillBeSent" do |params|
      received_events << :second_handler
    end

    server.send_msg({ method: "Network.requestWillBeSent" }.to_json)

    with_timeout do
      subject.listen_until { received_events.size == 2 }
    end

    expect(received_events).to include(:first_handler)
    expect(received_events).to include(:second_handler)
  end

  it "processes events when sending commands" do
    received_events = []
    
    subject.on "Network.requestWillBeSent" do |params|
      received_events << :first_handler
    end

    server.expect_msg do |msg|
      msg = JSON.parse(msg)
      server.send_msg({ method: "Network.requestWillBeSent" }.to_json)
      server.send_msg({ id: msg["id"] }.to_json)
    end

    with_timeout do
      subject.send_cmd "Page.navigate"
    end

    expect(received_events).to eq([:first_handler])
  end
  
end
