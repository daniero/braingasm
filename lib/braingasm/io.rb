module Braingasm
  class InputBuffer

    def initialize(source)
      @source = source
      @buffer = StringIO.new
    end

    def ungetc(s)
      case s
      when String
        @buffer.ungetc(s) if s.chomp.size > 0
      when Integer
        @buffer.ungetc(s) unless s == 10
      end
    end

    def getbyte
      @buffer.getbyte unless eof?
    end

    def gets
      @buffer.gets unless eof?
    end

    def eof?
      return true if @buffer.closed?
      return false unless @buffer.eof?

      s = @source.gets
      if s
        @buffer.string = s
        false
      else
        @buffer.close
        true
      end
    end

  end
end
