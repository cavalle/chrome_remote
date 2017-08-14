require "chrome_remote/version"
require "chrome_remote/client"

module ChromeRemote
  def self.client(*args, &block)
    Client.new(*args, &block)
  end
end
