require 'minitest/autorun'
require_relative '../lib/acquia-http-hmac'

class TestHTTPHmac < Minitest::Test

  def test_prepare_request_get
    mac = Acquia::HTTPHmac::Auth.new('TestRealm', "dGhlc2VjcmV0")
    args = {
      http_method: 'GET',
      host: 'www.example.com',
      id: 'test',
      path_info: '/hello',
    }
    headers = mac.prepare_request_headers(args)
    auth_header = headers['Authorization']
    assert(auth_header.match /acquia-http-hmac realm="TestRealm",id="test",nonce="[0-9a-f-]{36}",version="2\.0",headers="[^"]*",signature="[^"]+"/)

    # Repeat with known nonce and timestamp
    # "dGhlc2VjcmV0" is base64 of 'thesecret'
    mac = Acquia::HTTPHmac::Auth.new('TestRealm', "dGhlc2VjcmV0")
    args[:nonce] = "f2c91a46-b505-4b50-afa2-21364dc8ff34"
    args[:timestamp] = "1432180014"
    headers = mac.prepare_request_headers(args)
    auth_header = headers['Authorization']
    # We expect the following base string:
    # GET
    # www.example.com
    # /hello
    # 
    # id=test&nonce=f2c91a46-b505-4b50-afa2-21364dc8ff34&realm=TestRealm&version=2.0
    # 1432180014

    m = auth_header.match(/.*,signature="([^"]+)"$/)
    assert(m, 'Did not find signature')
    # Compare to a signature calulated with the base string in PHP.
    assert_equal("hKHBXbx9KDirAWpvYKGOqHVSLn6yjD3V5aaQTRklPPA=", m[1])
    # Repeast with a query string that needs to be normalized.
    args[:query_string] = 'base=foo&all'
    headers = mac.prepare_request_headers(args)
    auth_header = headers['Authorization']
    # We expect the following base string:
    # GET
    # www.example.com
    # /hello
    # base=foo&all
    # id=test&nonce=f2c91a46-b505-4b50-afa2-21364dc8ff34&realm=TestRealm&version=2.0
    # 1432180014
    m = auth_header.match(/.*,signature="([^"]+)"$/)
    assert(m, 'Did not find signature')
    # Compare to a signature calulated with the base string in PHP.
    assert_equal("dvl8wLvEcLbAtKfvIYaIGThIXHBpOtOTw7dQX4nBjwM=", m[1])
  end

  def test_prepare_request_get_headers
    mac = Acquia::HTTPHmac::Auth.new('TestRealm', "dGhlc2VjcmV0")
    args = {
      http_method: 'GET',
      host: 'www.example.com',
      id: 'test',
      path_info: '/hello',
      query_string: 'base=foo&all',
      nonce: "f2c91a46-b505-4b50-afa2-21364dc8ff34",
      timestamp: "1432180014",
      headers: {'x-custom-foo' => 'nick'}
    }
    headers = mac.prepare_request_headers(args)
    auth_header = headers['Authorization']
    assert(auth_header.match /acquia-http-hmac realm="TestRealm",id="test",nonce="[0-9a-f-]{36}",version="2\.0",headers="[^"]*",signature="[^"]+"/)

    # We expect the following base string:
    # GET
    # www.example.com
    # /hello
    # base=foo&all
    # id=test&nonce=f2c91a46-b505-4b50-afa2-21364dc8ff34&realm=TestRealm&version=2.0
    # x-custom-foo:nick
    # 1432180014
    m = auth_header.match(/.*,signature="([^"]+)"$/)
    assert(m, 'Did not find signature')
    # Compare to a signature calulated with the base string in PHP.
    assert_equal("RuYnAieiiOOWWAZ0tjZ/+HMebpBCBhGSYEWWBF+lP28=", m[1])
  end

  def test_prepare_request_post
    # Use known nonce and timestamp
    mac = Acquia::HTTPHmac::Auth.new('TestRealm', "dGhlc2VjcmV0")
    args = {
      http_method: 'POST',
      host: 'www.example.com',
      id: 'test',
      path_info: '/hello',
      nonce: "f2c91a46-b505-4b50-afa2-21364dc8ab34",
      timestamp: "1432180014",
    }
    args[:body] = '{"method":"hi.bob","params":["5","4","8"]}'
    args[:content_type] = 'application/json'
    headers = mac.prepare_request_headers(args)
    auth_header = headers['Authorization']
    assert(auth_header.match /acquia-http-hmac realm="TestRealm",id="test",nonce="[0-9a-f-]{36}",version="2\.0",headers="[^"]*",signature="[^"]+"/)
    assert_equal(headers['X-Authorization-Content-SHA256'], "6paRNxUA7WawFxJpRp4cEixDjHq3jfIKX072k9slalo=")
    # We expect the following base string:
    # POST
    # www.example.com
    # /hello
    # 
    # id=test&nonce=f2c91a46-b505-4b50-afa2-21364dc8ab34&realm=TestRealm&version=2.0
    # 1432180014
    # application/json
    # 6paRNxUA7WawFxJpRp4cEixDjHq3jfIKX072k9slalo=
    m = auth_header.match(/.*,signature="([^"]+)"$/)
    assert_equal("Un7AVsJ80yxzR0Jn+LB6orziDrAistPNm3h33bNZiJ0=", m[1])
  end

end
