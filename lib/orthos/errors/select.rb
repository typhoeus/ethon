module Orthos
  module Errors
    class Select < OrthosError
      def initialize(errno)
        super("An error occured on select: #{errno}")
      end
    end
  end
end

