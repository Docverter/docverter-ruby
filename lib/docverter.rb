require 'rest_client'
require 'docverter/json'
require "docverter/version"
require "docverter/conversion"

module Docverter

  class AuthenticationError < StandardError; end
  class APIConnectionError < StandardError; end
  class APIError < StandardError; end

  @@api_key = nil
  @@base_url = "https://api.docverter.com/v1"
  
  def self.api_key
    @@api_key
  end

  def self.api_key=(key)
    @@api_key = key
  end

  def self.api_url(path='')
    u = URI(@@base_url + path)
    key = self.api_key
    raise AuthenticationError.new('No API key provided. (HINT: set your API key using "Docverter.api_key = <API-KEY>". You can find your API in the Docverter web interface. See http://www.docverter.com/api.html for details, or email pete@docverter.com if you have any questions.)') if key.nil? && @@base_url == 'https://api.docverter.com/v1'
    u.user = key if key
    u.password = '' if key
    u.to_s
  end

  def self.base_url=(url)
    @@base_url = url
  end

  def self.reset
    @@api_key = nil
    @@base_url = 'https://api.docverter.com/v1'
  end

  def self.request(method, url, params={}, headers={})
    key = @@api_key

    url = self.api_url(url)

    headers = {
      :user_agent => "Docverter/v1 RubyBindings/#{Docverter::VERSION}",
      :content_type => "multipart/form-data"
    }.merge(headers)

    opts = {
      :method => method,
      :url => url,
      :headers => headers,
      :open_timeout => 30,
      :payload => params,
    }

    begin
      response = execute_request(opts)
    rescue SocketError => e
      self.handle_restclient_error(e)
    rescue NoMethodError => e
      # Work around RestClient bug
      if e.message =~ /\WRequestFailed\W/
        e = APIConnectionError.new('Unexpected HTTP response code')
        self.handle_restclient_error(e)
      else
        raise
      end
    rescue RestClient::ExceptionWithResponse => e
      if rcode = e.http_code and rbody = e.http_body
        self.handle_api_error(rcode, rbody)
      else
        self.handle_restclient_error(e)
      end
    rescue RestClient::Exception, Errno::ECONNREFUSED => e
      self.handle_restclient_error(e)
    end

    response.body
  end

  def self.execute_request(opts)
    RestClient::Request.execute(opts)
  end

  def self.handle_api_error(code, body)
    obj = Docverter::OkJson.decode(body) rescue {'error' => body}
    raise APIError.new("Docverter API Error: #{obj['error']} (status: #{code})")
  end

  def self.handle_restclient_error(e)
    case e
    when RestClient::ServerBrokeConnection, RestClient::RequestTimeout
      message = "Could not connect to Docverter (#{@@api_base}).  Please check your internet connection and try again.  If this problem persists, you should let me know at pete@docverter.com."
    when SocketError
      message = "Unexpected error communicating when trying to connect to Docverter.  HINT: You may be seeing this message because your DNS is not working.  To check, try running 'host docverter.com' from the command line."
    else
      message = "Unexpected error communicating with Docverter.  If this problem persists, let me know at pete@docverter.com."
    end
    message += "\n\n(Network error: #{e.message})"
    raise APIConnectionError.new(message)
  end
end

