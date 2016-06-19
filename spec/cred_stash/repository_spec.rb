require 'spec_helper'

describe CredStash::Repository do
  describe CredStash::Repository::DynamoDB do
    describe '#get' do
      it 'returns item'do
        stub_client = Aws::DynamoDB::Client.new(
          stub_responses: {
            query: {
              items: [
                { 'key' => 'data_key', 'contents' => 'contents' }
              ]
            }
          }
        )

        item = described_class.new(client: stub_client).get('name')
        expect(item.key).to eq 'data_key'
        expect(item.contents).to eq 'contents'
      end
    end
  end
end
