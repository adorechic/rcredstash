require 'spec_helper'

describe CredStash::Repository do
  describe CredStash::Repository::DynamoDB do
    describe '#get' do
      let(:stub_client) do
        Aws::DynamoDB::Client.new(
          stub_responses: { query: { items: items } }
        )
      end

      let(:items) do
        [{ 'key' => 'data_key', 'contents' => 'contents' }]
      end

      it 'returns item'do
        item = described_class.new(client: stub_client).get('name')
        expect(item.key).to eq 'data_key'
        expect(item.contents).to eq 'contents'
      end

      context 'if item is not found' do
        let(:items) { [] }

        it 'raises error' do
          expect{
            described_class.new(client: stub_client).get('name')
          }.to raise_error(CredStash::ItemNotFound)
        end
      end
    end
  end
end
