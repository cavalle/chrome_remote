require "websocket/driver"
require "chrome_remote/socket"

module ChromeRemote
  class WebSocketClient
    attr_reader :socket, :driver, :messages, :status

    def initialize(url, web_socket_options = {})
      @socket = ChromeRemote::Socket.new(url)
      @driver = ::WebSocket::Driver.client(socket, web_socket_options)

      @messages = []
      @status = :closed

      setup_driver
      start_driver
    end
    
    def send_msg(msg)
      driver.text msg
    end
    
    def read_msg
      parse_input until msg = messages.shift
      msg
    end

    private

    def setup_driver
      driver.on(:message) do |e|
        messages << e.data
      end
      
      driver.on(:error) do |e|
        raise e.message
      end
      
      driver.on(:close) do |e|
        @status = :closed
      end

      driver.on(:open) do |e|
        @status = :open
      end
    end

    def start_driver
      driver.start
      parse_input until status == :open
    end

    def parse_input
      @driver.parse(@socket.read)
    end
  end
end