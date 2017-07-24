require "chrome_remote/version"

require "websocket/driver"

class WebSocketClient
  
  attr_reader :url, :driver, :messages, :open
  attr_reader :driver
  
  def initialize(url)
    @url = url
    @driver = WebSocket::Driver.client(self)
    
    @messages = []
    @open = false
    
    driver.on(:message) do |e|
      @messages << e.data
    end
    
    driver.on(:error) do |e|
      raise e.message
    end
    
    driver.on(:close) do |e|
      @open = false
    end
    
    driver.on(:open) do |e|
      @open = true
    end
    
    driver.start
    
    driver.parse(read) while !@open
  end
  
  def send_msg(msg)
    driver.text msg
  end
  
  def read_msg
    driver.parse(read) until msg = messages.shift
    msg
  end
  
  def socket
    @socket ||= begin 
      uri = URI.parse(@url)
      TCPSocket.new uri.host, uri.port
    end
  end

  def write(data)
    socket.print data
  end

  def close
    socket.close
  end

  def read
    data = socket.readpartial(1024)
    data
  end
end

class ChromeRemote
  def initialize
    @ws = WebSocketClient.new("ws://127.0.0.1:9222/ws")
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
