require "chrome_remote/web_socket_client"
require "logger"

module ChromeRemote
  class Client
    attr_reader :ws, :handlers, :logger

    def initialize(ws_url, logger = nil)
      @ws = WebSocketClient.new(ws_url)
      @handlers = Hash.new { |hash, key| hash[key] = [] }
      @logger = logger || Logger.new(nil)
      @last_id = 0
    end

    def send_cmd(command, params = {})
      msg_id = generate_unique_id
      payload = {method: command, params: params, id: msg_id}.to_json

      logger.info "SEND ► #{payload}"
      ws.send_msg(payload)

      msg = read_until { |msg| msg["id"] == msg_id }
      msg["result"]
    end

    def on(event_name, &block)
      handlers[event_name] << block
    end

    def listen_until(&block)
      read_until { block.call }
    end

    def listen
      read_until { false }
    end

    def wait_for(event_name=nil)
      if event_name
        msg = read_until { |msg| msg["method"] == event_name }
      elsif block_given?
        msg = read_until { |msg| yield(msg["method"], msg["params"]) }
      end
      msg["params"]
    end

    private

    def generate_unique_id
      @last_id += 1
    end

    def read_msg
      msg = ws.read_msg
      logger.info "◀ RECV #{msg}"
      msg = JSON.parse(msg)

      # Check if it’s an event and invoke any handlers
      if event_name = msg["method"]
        handlers[event_name].each do |handler|
          handler.call(msg["params"])
        end
      end

      msg
    end

    def read_until(&block)
      loop do
        msg = read_msg
        return msg if block.call(msg)
      end
    end
  end
end
