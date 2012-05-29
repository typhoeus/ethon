module Orthos
  module Errors
    class Select < StandardError
      def initialize(errno)
        super("An error occured on select: #{errno}")
      end
    end
  end
end

