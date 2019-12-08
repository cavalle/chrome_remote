require "chrome_remote/version"
require "chrome_remote/client"
require "json"
require "net/http"

module ChromeRemote
  class ChromeConnectionError < RuntimeError; end

  class << self
    DEFAULT_OPTIONS = {
      host: "localhost",
      port: 9222
    }

    def client(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      logger = options.delete(:logger)

      Client.new(get_ws_url(options), logger)
    end

    private

    def get_ws_url(options)
      path = '/json'
      path += '/new?about:blank'  if options.key?(:new_tab)

      response = Net::HTTP.get(options[:host], path, options[:port])
      response = JSON.parse(response)

      raise ChromeConnectionError unless response.any?

      return response['webSocketDebuggerUrl'] if options.key?(:new_tab)

      first_page = response.find {|e| e["type"] == "page"}

      raise ChromeConnectionError unless first_page

      first_page["webSocketDebuggerUrl"]
    rescue ChromeConnectionError
      try ||= 0
      try += 1

      # Wait up to 5 seconds for Chrome to start fully
      if try <= 50
        sleep 0.1
        retry
      end
    end
  end
end
