module Braingasm
  module Options
    @options = {}
    @defaults = {
      eof: 0,
      wrap_cells: false,
      cell_limit: 256
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

  def self.handle_options(**command_line_options)
    Options[:eof] = 0 if command_line_options[:zero]
    Options[:eof] = -1 if command_line_options[:negative]
    Options[:eof] = nil if command_line_options[:as_is]

    Options[:wrap_cells] = true if command_line_options[:wrap_cells] ||
                                   command_line_options[:cell_size_given]

    if command_line_options[:cell_size_given]
      cell_size = command_line_options[:cell_size]
      Options[:cell_limit] = 2**cell_size
    end
  end
end
