module Braingasm
  module Options
    @options = {}
    @defaults = {
      eof: 0
    }.freeze

    def self.[](option)
      return @options[option] if @options.has_key?(option)
      check_defaults(option)
      @defaults[option]
    end

    def self.[]=(option, value)
      check_defaults(option)
      @options[option] = value
    end

    private
    def self.check_defaults(option)
      raise ArgumentError, "Unknown option '#{option}'" unless @defaults.has_key?(option)
    end
  end

  def self.handle_options(options)
    Options[:eof] = 0 if options[:zero]
    Options[:eof] = -1 if options[:negative]
    Options[:eof] = nil if options[:as_is]
  end
end
