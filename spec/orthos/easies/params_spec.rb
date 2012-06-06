require 'spec_helper'

describe Orthos::Easies::Params do
  let(:hash) { {} }
  let(:params) { Orthos::Easies::Params.new(hash) }

  describe "#to_s" do
    context "when query_pairs empty" do
      before { params.instance_variable_set(:@query_pairs, []) }

      it "returns empty string" do
        params.to_s.should eq("")
      end
    end

    context "when query_pairs not empty" do
      before { params.instance_variable_set(:@query_pairs, [[:a, 1], [:b, 2]]) }

      it "returns concatenated query string" do
        params.to_s.should eq("a=1&b=2")
      end
    end
  end
end
