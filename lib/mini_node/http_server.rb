require 'mini_node'
require 'mini_node/request'
require 'mini_node/response'

module MiniNode
  class HttpServer
    attr_reader :reactor, :server

    def initialize(host, port)
      @reactor = MiniNode::Reactor.new
      @server  = @reactor.listen(host, port)
    end

    def start(&block)
      hit_count = 0

      server.on :accept do |client|
        hit_count += 1
        process_request client, hit_count, &block
      end

      reactor.start
    end

    protected

    def process_request(client, hit_count, &block)
      request  = MiniNode::Request.new
      response = MiniNode::Response.new(client)

      client.on :data do |data|
        request.http_parser << data
      end

      request.http_parser.on_message_complete = lambda do
        puts({ hit_count: hit_count, request: [request.verb, request.url] }.inspect)

        block.call request, response

        puts({ response: [response.status_code, response.headers] }.inspect)
      end
    end
  end
end
