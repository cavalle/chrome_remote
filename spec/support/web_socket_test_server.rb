require "em-websocket"

class WebSocketTestServer
  attr_reader :host, :port, :msg_handlers, :server, :thread, :path, :query

  def initialize(url)
    uri = URI.parse(url)
    @host  = uri.host
    @port  = uri.port
    @path  = uri.path
    @query = uri.query

    @msg_handlers = []

    start_reactor
    start_server
  end

  def expect_msg(&block)
    msg_handlers << block
  end

  def send_msg(msg)
    server.send msg
  end

  def close
    EM.stop if EM.reactor_running?
    thread.join rescue nil #FIXME: Find other way to avoid thread exceptions to be raised again
  end

  def has_satisfied_all_expectations?
    msg_handlers.empty?
  end

  private

  def start_reactor
    @thread = Thread.new { EM.run }
    thread.abort_on_exception = true

    while not EM.reactor_running?; end
  end

  def start_server
    EM::WebSocket.run(:host => host, :port => port) do |ws|
      ws.onopen do |handshake|
        if handshake.path.to_s != path.to_s
          raise "Expected WebSocket path: #{path}. Got: #{handshake.path}"
        end

        if handshake.query_string.to_s != query.to_s
          raise "Expected WebSocket query_string: '#{query}'. Got: '#{handshake.query_string}'"
        end
      end

      ws.onmessage do |msg|
        handler = msg_handlers.shift
        handler.call(msg)
      end

      @server = ws
    end
  end
end
