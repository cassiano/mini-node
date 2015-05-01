module MiniNode
  class Response
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def add_header(name, value)
      client.write "#{name}: #{value}\r\n"
    end

    def add_new_line
      client.write "\r\n"
    end

    def length=(length)
      add_header 'Content-Length', length
    end

    def type=(type)
      add_header 'Content-Type', type
    end

    def last_modified=(last_modified)
      add_header 'Last-Modified', last_modified.httpdate
    end

    def status_code=(code)
      case code
      when 200, :ok
        client.write("HTTP/1.1 200 OK\r\n")
      when 304, :not_modified
        client.write("HTTP/1.1 304 Not Modified\r\n")
      when 403, :forbidden
        client.write("HTTP/1.1 403 Forbidden\r\n")
      when 404, :not_found
        client.write("HTTP/1.1 404 Not Found\r\n")
      else
        raise "Invalid HTTP status code #{code}"
      end
    end

    def finish
      client.close
    end
  end
end
