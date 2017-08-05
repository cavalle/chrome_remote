require "chrome_remote/web_socket_client"

module ChromeRemote
  class Client
    attr_reader :ws

    def initialize
      @ws = WebSocketClient.new("ws://127.0.0.1:9222/ws?active=true")
    end
  
    def send_cmd(command, params = {})  
      msg_id = generate_unique_id
      
      ws.send_msg({method: command, params: params, id: msg_id}.to_json)
      
      loop do
        msg = read_msg
        return msg["result"] if msg["id"] == msg_id
      end
    end
  
    private
  
    def generate_unique_id
      @last_id ||= 0
      @last_id += 1
    end

    def read_msg
      JSON.parse(ws.read_msg)
    end
  end
end