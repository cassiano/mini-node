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
      server.on(:accept) do |client|
        process_request client, &block
      end

      reactor.start
    end

    protected

    def process_request(client, &block)
      request  = MiniNode::Request.new
      response = MiniNode::Response.new(client)

      client.on(:data) do |data|
        request.http_parser << data
      end

      request.http_parser.on_message_complete = lambda do
        block.call request, response, reactor
      end
    end
  end
end
