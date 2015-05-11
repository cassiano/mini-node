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
      count = 0

      server.on :accept do |client|
        count += 1
        process_request client, count, &block
      end

      reactor.start
    end

    protected

    def process_request(client, count, &block)
      request  = MiniNode::Request.new
      response = MiniNode::Response.new(client)

      client.on :data do |data|
        request.http_parser << data
      end

      request.http_parser.on_message_complete = lambda do
        block.call request, response

        log_message = {
          count: count,
          request: [request.verb, request.url],
          response: [response.status_code, response.headers]
        }.inspect

        puts log_message
      end
    end
  end
end
