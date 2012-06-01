begin 
  # try to use require_relative first
  # this only works for 1.9
  require_relative 'orderbridge.rb'
rescue NameError
  # oops, must be using 1.8
  # no problem, this will load it then
  require File.expand_path('orderbrige.rb', __FILE__)
end

require 'test/unit'
require 'rack/test'

class OrderBridgeTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

end
