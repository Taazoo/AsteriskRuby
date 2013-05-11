class AgiRouteFilterChain
  attr_accessor :filters

  def initialize
    @filters = []
  end

  class ExtendableClassMethods
    class << self
      def filter_chain(filter_method)
        chain  = filter_method.to_sym
        @filter_chain        ||= {}
        @filter_chain[chain] ||= []
        @filter_chain[chain]
      end

      def before_filter(method_sym)
        filter_chain(:before).push method_sym
      end

      def after_filter(method_sym)
        filter_chain(:after).push method_sym
      end

      def run_filter_chain(chain)
        result = true
        active_filters = self.class.filter_chain(chain)
        active_filters.each do |filter|
          result = self.method(filter).call()
          if result == false
            raise AGIFilterHalt.new("Filter chain halted execution: #{filter}")
          end
        end
      end

    end

  end

end
