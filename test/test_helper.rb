lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docverter'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'tempfile'

module Docverter
  @mock_rest_client = nil

  def self.mock_rest_client=(mock_client)
    @mock_rest_client = mock_client
  end

  def self.execute_request(opts)
    get_params = (opts[:headers] || {})[:params]
    post_params = opts[:payload]
    case opts[:method]
    when :get then @mock_rest_client.get opts[:url], get_params, post_params
    when :post then @mock_rest_client.post opts[:url], get_params, post_params
    when :delete then @mock_rest_client.delete opts[:url], get_params, post_params
    end
  end
end

def test_response(body, code=200)
  m = mock
  m.instance_variable_set('@docverter_values', { :body => body, :code => code })
  def m.body; @docverter_values[:body]; end
  def m.code; @docverter_values[:code]; end
  m
end
