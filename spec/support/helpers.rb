module Helpers
  def with_timeout(timeout = 5, &block)
    # TODO should the library implement timeouts on all the operations instead?
    Timeout::timeout(timeout, &block)
  end
end

RSpec.configure do |c|
  c.include Helpers
end