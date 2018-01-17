require "spec_helper"
require "json"

RSpec.describe ChromeRemote do
  around(:each) do |example|
    # TODO should the library implement timeouts on every operation instead?
    Timeout::timeout(5) { example.run }
  end

  WS_URL = "ws://localhost:9222/devtools/page/4a64d04e-f346-4460-be97-98e4a3dbf2fc"

  before(:each) do
    stub_request(:get, "http://localhost:9222/json").to_return(
      body: [{ "type": "page", "webSocketDebuggerUrl": WS_URL }].to_json
    )
  end

  # Server needs to be running before the client
  let!(:server) { WebSocketTestServer.new(WS_URL) }
  let!(:client) { ChromeRemote.client }

  after(:each) { server.close }

  describe "Initializing a client" do
    it "returns a new client" do
      client = double("client")
      expect(ChromeRemote::Client).to receive(:new).with(WS_URL) { client }
      expect(ChromeRemote.client).to eq(client)
    end

    it "uses the first page’s webSocketDebuggerUrl" do
      stub_request(:get, "http://localhost:9222/json").to_return(
        body: [
          { "type": "background_page", "webSocketDebuggerUrl": "ws://one"   },
          { "type": "page",            "webSocketDebuggerUrl": "ws://two"   },
          { "type": "page",            "webSocketDebuggerUrl": "ws://three" }
        ].to_json
      )

      expect(ChromeRemote::Client).to receive(:new).with("ws://two")
      ChromeRemote.client
    end

    it "gets pages from the given host and port" do
      stub_request(:get, "http://192.168.1.1:9292/json").to_return(
        body: [{ "type": "page", "webSocketDebuggerUrl": "ws://one" }].to_json
      )
      expect(ChromeRemote::Client).to receive(:new).with("ws://one")
      ChromeRemote.client host: '192.168.1.1', port: 9292
    end
  end

  describe "Sending commands" do
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

      response = client.send_cmd "Page.navigate", url: "https://github.com"

      expect(response).to eq(expected_result)
      expect(server).to have_satisfied_all_expectations
    end
  end

  describe "Subscribing to events" do
    it "subscribes to events using the DevTools protocol" do
      received_events = []

      client.on "Network.requestWillBeSent" do |params|
        received_events << ["Network.requestWillBeSent", params]
      end

      client.on "Page.loadEventFired" do |params|
        received_events << ["Page.loadEventFired", params]
      end

      server.send_msg({ method: "RandomEvent" }.to_json) # to be ignored
      server.send_msg({ method: "Network.requestWillBeSent", params: { "param" => 1} }.to_json)
      server.send_msg({ id: 999, result: { "frameId" => 2 } }.to_json) # to be ignored
      server.send_msg({ method: "Page.loadEventFired",       params: { "param" => 2} }.to_json)
      server.send_msg({ method: "Network.requestWillBeSent", params: { "param" => 3} }.to_json)

      expect(received_events).to be_empty # we haven't listened yet

      client.listen_until { received_events.size == 3 }

      expect(received_events).to eq([
        ["Network.requestWillBeSent", { "param" => 1}],
        ["Page.loadEventFired",       { "param" => 2}],
        ["Network.requestWillBeSent", { "param" => 3}],
      ])
    end

    it "allows to subscribe multiple times to the same event" do
      received_events = []
      
      client.on "Network.requestWillBeSent" do |params|
        received_events << :first_handler
      end

      client.on "Network.requestWillBeSent" do |params|
        received_events << :second_handler
      end

      expect(received_events).to be_empty # we haven't listened yet

      server.send_msg({ method: "Network.requestWillBeSent" }.to_json)

      client.listen_until { received_events.size == 2 }

      expect(received_events).to include(:first_handler)
      expect(received_events).to include(:second_handler)
    end

    it "processes events when sending commands" do
      received_events = []
      
      client.on "Network.requestWillBeSent" do |params|
        received_events << :first_handler
      end

      server.expect_msg do |msg|
        msg = JSON.parse(msg)
        server.send_msg({ method: "Network.requestWillBeSent" }.to_json)
        server.send_msg({ id: msg["id"] }.to_json)
      end

      expect(received_events).to be_empty # we haven't listened yet

      client.send_cmd "Page.navigate"

      expect(received_events).to eq([:first_handler])
    end

    it "subscribes to events and process them indefinitely" do
      expected_events = rand(10) + 1
      received_events = 0

      TestError = Class.new(StandardError)
      
      client.on "Network.requestWillBeSent" do |params|
        received_events += 1
        # the client will listen indefinitely, raise an expection to get out of the loop
        raise TestError if received_events == expected_events
      end
      
      expected_events.times do
        server.send_msg({ method: "Network.requestWillBeSent" }.to_json)
      end

      expect(received_events).to be_zero # we haven't listened yet

      expect{client.listen}.to raise_error(TestError)

      expect(received_events).to be(expected_events)
    end
  end

  describe "Waiting for events" do
    it "waits for the next instance of an event" do
      # first two messages are to be ignored
      server.send_msg({ id: 99 }.to_json)
      server.send_msg({ method: "Network.requestWillBeSent", params: { "event" => 1 } }.to_json)
      server.send_msg({ method: "Page.loadEventFired",       params: { "event" => 2 } }.to_json)
      server.send_msg({ method: "Network.requestWillBeSent", params: { "event" => 3 } }.to_json)
    
      result = client.wait_for("Page.loadEventFired")
      expect(result).to eq({ "event" => 2 })

      result = client.wait_for("Network.requestWillBeSent")
      expect(result).to eq({ "event" => 3 })
    end

    it "subscribes and waits for the same event" do
      received_events = 0
      
      client.on "Network.requestWillBeSent" do |params|
        received_events += 1
      end

      server.send_msg({ method: "Network.requestWillBeSent" }.to_json)

      expect(received_events).to be_zero # we haven't listened yet

      result = client.wait_for("Network.requestWillBeSent")
      expect(received_events).to eq(1)
    end

    it "waits for events with custom matcher block" do
      server.send_msg({ method: "Page.lifecycleEvent", params: { "name" => "load" }}.to_json)
      server.send_msg({ method: "Page.lifecycleEvent", params: { "name" => "DOMContentLoaded" }}.to_json)
      result = client.wait_for do |event_name, event_params|
        event_name == "Page.lifecycleEvent" && event_params["name"] == "DOMContentLoaded"
      end

      expect(result).to eq({"name" => "DOMContentLoaded"})
    end
  end
end
