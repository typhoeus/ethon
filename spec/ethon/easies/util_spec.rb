require 'spec_helper'

describe Ethon::Easies::Util do
  let(:hash) { {} }
  let(:params) { Ethon::Easies::Params.new(hash) }

  describe "#build_query_pairs_from_hash" do
    let(:pairs) { params.method(:build_query_pairs_from_hash).call(hash) }

    context "when params is empty" do
      it "returns empty array" do
        pairs.should eq([])
      end
    end

    context "when params is simple hash" do
      let(:hash) { {:a => 1, :b => 2} }

      it "transforms correct" do
        pairs.should eq([[:a, 1], [:b, 2]])
      end
    end

    context "when params is a nested hash" do
      let(:hash) { {:a => 1, :b => {:c => 2}} }

      it "transforms correct" do
        pairs.should eq([[:a, 1], ["b[c]", 2]])
      end
    end

    context "when params contains an array" do
      let(:hash) { {:a => 1, :b => [2, 3]} }

      it "transforms correct" do
        pairs.should eq([[:a, 1], [:b, 2], [:b, 3]])
      end
    end

    context "when params contains file" do
      let(:file) { Tempfile.new("fubar") }
      let(:file_info) { params.method(:file_info).call(file) }
      let(:hash) { {:a => 1, :b => file} }

      it "transforms correct" do
        pairs.should eq([[:a, 1], [:b, file_info]])
      end
    end
  end
end
