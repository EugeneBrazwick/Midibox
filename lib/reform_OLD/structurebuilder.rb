
module Reform
  class StructureBuilder
    include ModelContext
    private

    public

      def build &block
        tag "build"
        @result = {}
        instance_eval(&block)
        tag "build #{@result.inspect}"
        @result
      end

#       def parent_qtc_to_use_for reform_class
#       end

      def method_missing symbol, *args, &block
        tag "method_missing :#{symbol}"
        if symbol.to_s[-1] == '='
          raise Error, 'cannot accept block' if block
          @result[symbol.to_s[0...-1].to_sym] = *args
        elsif args.length == 0 && @result.has_key?(symbol)
          @result[symbol]
        else
          super
        end
      end
  end
end