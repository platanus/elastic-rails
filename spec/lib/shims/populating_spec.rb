require 'spec_helper'

describe Elastic::Shims::Populating do
  let(:foo_type) { build_type('FooType', :id, :foo, :bar, :tags) }

  let(:index) do
    build_index('FooIndex', target: foo_type, migrate: true) do
      field :foo, type: :string
      field :bar, type: :long
      nested :tags do
        field :name, type: :term
      end
    end
  end

  let(:middleware) { index.definition.main_target }
  let(:config) { Elastic::Core::QueryConfig.initial_config }
  let(:child) { Elastic::Nodes::Search.build build_node('dummy') }

  let(:node) { described_class.new(index, config, child) }

  context "middleware uses index mode" do
    before do
      allow(middleware).to receive(:mode).and_return(:index)
      allow(middleware).to receive(:find_by_ids) { |ids| ids.map { |i| "obj_#{i}" } }
    end

    describe "render" do
      it "sets the source property for Search nodes" do
        expect { node.render }.to change { child.source }
      end
    end

    describe "handle_result" do
      let(:hit_1) { Elastic::Results::Hit.new('_type' => 'FooType', '_id' => 1) }
      let(:hit_2) { Elastic::Results::Hit.new('_type' => 'FooType', '_id' => 2) }
      let(:result) { Elastic::Results::Root.new([hit_1, hit_2], {}) }

      before do
        allow(child).to receive(:handle_result).and_return result
      end

      it "calls the child node 'handle_result'" do
        node.handle_result :foo
        expect(child).to have_received(:handle_result).with(:foo)
      end

      it "populates the result " do
        expect { node.handle_result({}) }.to change { hit_1.data }
        expect(hit_1.data).to eq 'obj_1'
        expect(hit_2.data).to eq 'obj_2'
      end
    end
  end

  context "middleware uses storage mode" do
    before do
      allow(middleware).to receive(:mode).and_return(:storage)
      allow(middleware).to receive(:build_from_data) { |data| OpenStruct.new(data) }
    end

    describe "render" do
      it "does not set the source property" do
        expect { node.render }.not_to change { child.source }
      end
    end

    describe "handle_result" do
      let(:hit_1) { Elastic::Results::Hit.new('_type' => 'FooType', '_source' => { foo: 'hello' }) }
      let(:hit_2) { Elastic::Results::Hit.new('_type' => 'FooType', '_source' => { foo: 'world' }) }
      let(:result) { Elastic::Results::Root.new([hit_1, hit_2], {}) }

      before do
        allow(child).to receive(:handle_result).and_return result
      end

      it "populates the result by calling 'build_from_data'" do
        expect { node.handle_result({}) }.to change { hit_1.data }.to be_a OpenStruct
        expect(hit_1.data.foo).to eq 'hello'
        expect(hit_2.data.foo).to eq 'world'
      end
    end
  end
end
