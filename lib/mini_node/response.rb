module MiniNode
  class Response
    attr_reader :client, :status_code, :headers, :body

    def initialize(client)
      @client = client
      @body   = ''
    end

    def set_head(status_code, headers = [])
      self.status_code = status_code
      self.headers     = headers
    end

    def write(text)
      @body << text

      client.write text
    end

    def finish
      client.close
    end

    protected

    def headers=(headers)
      @headers = headers

      headers.each do |(name, value)|
        add_header name, value
      end

      write_head ''
    end

    def add_header(name, value)
      write_head "#{name}: #{value}" if value
    end

    def write_head(text_line)
      client.write "#{text_line}\r\n"
    end

    def status_code=(status_code)
      @status_code = status_code

      case status_code
        when 200, :ok
          write_head 'HTTP/1.1 200 OK'
        when 304, :not_modified
          write_head 'HTTP/1.1 304 Not Modified'
        when 404, :not_found
          write_head 'HTTP/1.1 404 Not Found'
        when 405, :method_not_allowed
          write_head 'HTTP/1.1 405 Method not allowed'
        else
          raise "Invalid HTTP status code #{code}"
      end
    end
  end
end
