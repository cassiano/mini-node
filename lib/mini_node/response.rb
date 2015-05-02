module MiniNode
  class Response
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def write(text)
      client.write text
    end

    def writeln(text_line)
      write "#{text_line}\r\n"
    end

    def add_header(name, value)
      writeln "#{name}: #{value}"
    end

    def mark_start_of_body
      writeln ''
    end

    def body=(body)
      mark_start_of_body
      write body
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
        writeln 'HTTP/1.1 200 OK'
      when 304, :not_modified
        writeln 'HTTP/1.1 304 Not Modified'
      when 404, :not_found
        writeln 'HTTP/1.1 404 Not Found'
      when 405, :method_not_allowed
        writeln 'HTTP/1.1 405 Method not allowed'
      else
        raise "Invalid HTTP status code #{code}"
      end
    end

    def finish
      client.close
    end
  end
end
