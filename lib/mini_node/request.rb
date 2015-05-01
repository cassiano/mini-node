require 'time'

module MiniNode
  class Request
    attr_reader :http_parser

    def initialize(http_parser)
      @http_parser = http_parser
    end

    def verb
      http_parser.http_method
    end

    def url
      http_parser.request_url
    end

    def headers
      http_parser.headers
    end

    [:get, :put, :delete, :post, :patch, :head].each do |http_method|
      define_method "#{http_method}?" do
        verb.downcase.to_sym == http_method
      end
    end

    def if_modified_since
      @if_modified_since ||= (http_date = headers['If-Modified-Since']) && Time.parse(http_date)
    end
  end
end
