require "forwardable"

module Braingasm

  class PrefixStack
    extend Forwardable
    attr_accessor :stack
    def_delegators :@stack, :empty?, :<<, :pop, :==, :first, :last

    def initialize
      @stack = []
    end

    def fix_params(function, default_param=1)
      prefix = @stack.pop || default_param

      case prefix
      when Integer, String
        function.curry.call(prefix)
      when Proc
        proc do |m|
          n = prefix.call(m)
          function.call(n, m)
        end
      end
    end

  end

end
