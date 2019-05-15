require "chrome_remote/version"
require "chrome_remote/client"
require "json"
require "net/http"

module ChromeRemote
  class << self
    DEFAULT_OPTIONS = {
      host: "localhost",
      port: 9222
    }

    def client(options = {})
      options = DEFAULT_OPTIONS.merge(options)

      Client.new(get_ws_url(options))
    end

    private

    def get_ws_url(options)
      query = options[:token] ? "?token=#{options[:token]}" : ''
      return options[:ws_endpoint_url] + query if options[:ws_endpoint_url]

      get_from_json_response(options, query)
    end

    def get_from_json_response(options, query)
      response = Net::HTTP.get(options[:host], "/json" + query, options[:port])
      # TODO handle unsuccesful request
      response = JSON.parse(response)

      first_page = response.find {|e| e["type"] == "page"}
      # TODO handle no entry found
      first_page["webSocketDebuggerUrl"] + query
    end
  end
end
