require "chrome_remote/web_socket"

module ChromeRemote
  class Client
    def initialize
      @ws = WebSocket.new("ws://127.0.0.1:9222/ws")
    end
  
    def send_cmd(command, params = {})  
      id = generate_unique_id
      @ws.send_msg({method: command, params: params, id: id}.to_json)
      response = nil
      loop do
        response = read_msg
        break if response["id"] == id
      end
      response["result"]
    end
  
    def read_msg
      msg = @ws.read_msg
      JSON.parse msg
    end
  
    private
  
    def generate_unique_id
      @ids ||= 0
      @ids += 1
    end
  end
end