module MiniNode
  class Stream
    attr_reader :total_bytes_written, :total_bytes_read

    include EventEmitter

    CHUNK_SIZE = 512 * 1024

    def initialize(io)
      @io           = io
      @write_buffer = ''

      @total_bytes_written = 0
      @total_bytes_read    = 0
    end

    def closed?
      @io.closed?
    end

    def handle_read
      puts ">>> handle_read called" if DEBUG_MODE

      data = @io.read_nonblock(CHUNK_SIZE)
      @total_bytes_read += data.bytesize
      emit :data, data
    rescue EOFError, Errno::ECONNRESET
      close
    end

    def handle_write
      flush

      emit(:empty_write_buffer) if @write_buffer.empty?
    end

    def write(data)
      if DEBUG_MODE
        chomped_data = data.chomp

        if chomped_data.size > 40
          puts "Writing `#{chomped_data[0..19].inspect} ... #{chomped_data[-20..-1].inspect}`"
        else
          puts "Writing `#{chomped_data.inspect}`"
        end
      end

      @write_buffer << data unless data.empty?

      bytes_written = @io.write_nonblock(@write_buffer)
      @total_bytes_written += bytes_written
      @write_buffer = @write_buffer[bytes_written..-1] || ''

      if DEBUG_MODE
        puts "#{bytes_written} bytes written"
        puts "#{@write_buffer.bytesize} bytes remaining"
      end
    rescue Errno::EAGAIN, Errno::EPIPE
    end

    def close
      if @write_buffer.empty?
        emit(:close)
        @io.close
      else
        on(:empty_write_buffer) do
          emit(:close)
          @io.close
        end
      end
    end

    def pipe_to(another_stream)
      on(:data) do |data|
        another_stream.write(data)
      end
    end

    def to_io
      @io
    end

    def to_s
      @io.class.to_s
    end

    protected

    def flush
      write('') unless @write_buffer.empty?
    end
  end
end
