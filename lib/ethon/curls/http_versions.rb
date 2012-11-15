module Ethon
  module Curls

    # This module contains the available proxy types.
    module HttpVersions

      # Return http versions.
      #
      # @example Return http versions.
      #   Ethon::Curl.http_versions
      #
      # @return [ Hash ] The http_versions.
      def http_versions
        {
          :none => 0,
          :httpv1_0  => 1,
          :httpv1_1  => 2
        }
      end
    end
  end
end
