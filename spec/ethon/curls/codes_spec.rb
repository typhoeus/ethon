# frozen_string_literal: true
require 'spec_helper'

describe Ethon::Curl::MultiCode do
  {
    :call_multi_perform => -1,
    :ok => 0,
    :bad_handle => 1,
    :bad_easy_handle => 2,
    :out_of_memory => 3,
    :internal_error => 4,
    :bad_socket => 5,
    :unknown_option => 6,
    :added_already => 7,
    :recursive_api_call => 8,
    :wakeup_failure => 9,
    :bad_function_argument => 10,
    :aborted_by_callback => 11,
    :unrecoverable_poll => 12,
    :last => 13
  }.each do |name, value|
    it "maps #{name} to #{value}" do
      expect(described_class[name]).to eq(value)
      expect(described_class[value]).to eq(name)
    end
  end
end
