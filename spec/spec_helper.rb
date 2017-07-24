require "bundler/setup"
require "chrome_remote"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require "em-websocket"

class WebServiceServerMock
  def initialize(host: nil, port: nil)
    Thread.abort_on_exception = true
    @thread = Thread.new { EM.run }
    @msg_handlers = []
    while not EM.reactor_running?; end
    EM::WebSocket.run(:host => host, :port => port) do |ws|
      @ws = ws
      ws.onmessage { |msg|
        puts "Recieved message: #{msg}"
        handler = @msg_handlers.pop
        handler.call(msg)
      }
    end
  end

  def expect_message(&block)
    @msg_handlers << block
  end

  def send_message(msg)
    @ws.send msg
  end

  def close
    EM.stop
    @thread.join
  end

  def has_satisfied_all_expectations?
    @msg_handlers.empty?
  end
end