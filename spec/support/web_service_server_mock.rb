require "em-websocket"

class WebServiceServerMock
  attr_reader :host, :port, :msg_handlers, :server, :thread

  def initialize(host: nil, port: nil)
    @host = host
    @port = port
    @msg_handlers = []

    start_reactor
    start_server
  end

  def expect_message(&block)
    msg_handlers << block
  end

  def send_message(msg)
    server.send msg
  end

  def close
    EM.stop
    thread.join
  end

  def has_satisfied_all_expectations?
    msg_handlers.empty?
  end

  private

  def start_reactor
    Thread.abort_on_exception = true
    @thread = Thread.new { EM.run }    
    while not EM.reactor_running?; end
  end

  def start_server
    EM::WebSocket.run(:host => host, :port => port) do |ws|
      ws.onmessage do |msg|
        handler = msg_handlers.shift
        handler.call(msg)
      end

      @server = ws
    end
  end
end