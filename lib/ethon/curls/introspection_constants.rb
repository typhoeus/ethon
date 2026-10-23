# frozen_string_literal: true
module Ethon
  module Curl
    # The struct age at which curl_version_info_data exposes feature_names.
    CURLVERSION_ELEVENTH = 10

    # CURLHcode values.
    HeaderCode = enum(:header_code, [
      :ok,
      :badindex,
      :missing,
      :noheaders,
      :norequest,
      :out_of_memory,
      :bad_argument,
      :not_built_in
    ])

    # CURLH_* origin bits.
    HeaderOrigin = bitmask(:header_origin, [
      nil,
      :header,
      :trailer,
      :connect,
      :"1xx",
      :pseudo
    ])

    # curl_easytype values used by curl_easy_option_*.
    EasyType = enum(:easy_type, [
      :long,
      :values,
      :off_t,
      :object,
      :string,
      :slist,
      :cbptr,
      :blob,
      :function
    ])
  end
end
