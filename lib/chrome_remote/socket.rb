require "socket"

module ChromeRemote
  class Socket
    attr_reader :url, :io

    def initialize(url)
      uri = URI.parse(url)

      @url = url
      @io = TCPSocket.new(uri.host, uri.port)
    end

    def write(data)
      io.print data
    end

    def read
      io.readpartial(1024)
    end
  end
end
