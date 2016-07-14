require 'spec_helper'

describe Elastic::Nodes::FunctionScore do
  let(:query) { build_node 'foo' }
  let(:node) { described_class.build query  }

  describe "boost_mode=" do
    it "only allows valid mode values" do
      expect { node.boost_mode = :replace }.not_to raise_error
      expect { node.boost_mode = :sum }.not_to raise_error
      expect { node.boost_mode = :foo }.to raise_error ArgumentError
    end
  end

  describe "score_mode=" do
    it "only allows valid mode values" do
      expect { node.score_mode = :sum }.not_to raise_error
      expect { node.score_mode = :replace }.to raise_error ArgumentError
      expect { node.score_mode = :foo }.to raise_error ArgumentError
    end
  end

  describe "simplify" do
    it "returns the query object" do
      expect(node.simplify).to eq query
    end
  end

  context "a boost has been set" do
    before { node.boost = 2.0 }

    describe "simplify" do
      describe "render" do
        it "renders correctly" do
          expect(node.render)
            .to eq('function_score' => { 'query' => 'foo', 'boost' => 2.0 })
        end
      end

      it "returns the query object with the boost set to the parent value" do
        expect(node.simplify).to be_a query.class
        expect(node.simplify.boost).to eq 2.0
      end
    end
  end

  context "a weight function has been applied" do
    before { node.add_weight_function(2.0) }

    describe "render" do
      it "renders correctly" do
        expect(node.render)
          .to eq('function_score' => { 'query' => 'foo', 'weight' => 2.0 })
      end
    end

    context "the boost mode is changed" do
      before { node.boost_mode = :replace }

      describe "render" do
        it "renders correctly" do
          expect(node.render)
            .to eq(
              'function_score' => {
                'query' => 'foo',
                'weight' => 2.0,
                'boost_mode' => 'replace'
              }
            )
        end
      end
    end

    context "then a field function is applied" do
      before do
        node.add_field_function('foo', factor: 2, modifier: 'sqrt', missing: 2)
      end

      describe "render" do
        it "renders correctly" do
          expect(node.render)
            .to eq(
              'function_score' => {
                'query' => 'foo',
                'functions' => [
                  {
                    'weight' => 2.0
                  },
                  {
                    'field_value_factor' => {
                      'field' => 'foo',
                      'factor' => 2,
                      'modifier' => 'sqrt',
                      'missing' => 2
                    }
                  }
                ]
              }
            )
        end
      end
    end
  end
end
