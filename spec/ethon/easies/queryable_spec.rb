require 'spec_helper'

describe Ethon::Easies::Queryable do
  let(:hash) { {} }
  let(:params) { Ethon::Easies::Params.new(hash) }

  describe "#to_s" do
    context "when query_pairs empty" do
      before { params.instance_variable_set(:@query_pairs, []) }

      it "returns empty string" do
        params.to_s.should eq("")
      end
    end

    context "when query_pairs not empty" do
      context "when escape" do
        before do
          params.escape = true
          params.instance_variable_set(:@query_pairs, [[:a, "1&b=2"]])
        end

        it "returns concatenated escaped query string" do
          params.to_s.should eq("a=1%26b%3D2")
        end
      end

      context "when no escape" do
        before { params.instance_variable_set(:@query_pairs, [[:a, 1], [:b, 2]]) }

        it "returns concatenated query string" do
          params.to_s.should eq("a=1&b=2")
        end
      end
    end

    context "when query_pairs contains a string" do
      before { params.instance_variable_set(:@query_pairs, ["{a: 1}"]) }

      it "returns correct string" do
        params.to_s.should eq("{a: 1}")
      end
    end
  end

  describe "#build_query_pairs" do
    let(:pairs) { params.method(:build_query_pairs).call(hash) }

    context "when params is empty" do
      it "returns empty array" do
        pairs.should eq([])
      end
    end

    context "when params is string" do
      let(:hash) { "{a: 1}" }

      it "wraps it in an array" do
        pairs.should eq([hash])
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

    context "when params key contains a null byte" do
      let(:hash) { {:a => "1\0" } }

      it "escapes" do
        pairs.should eq([[:a, "1\\0"]])
      end
    end

    context "when params value contains a null byte" do
      let(:hash) { {"a\0" => 1 } }

      it "escapes" do
        pairs.should eq([["a\\0", 1]])
      end
    end
  end

  describe "#empty?" do
    context "when params empty" do
      it "returns true" do
        params.empty?.should be_true
      end
    end

    context "when params not empty" do
      let(:hash) { {:a => 1} }

      it "returns false" do
        params.empty?.should be_false
      end
    end
  end
end
