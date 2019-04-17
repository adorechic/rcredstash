require 'spec_helper'

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

  describe '#put' do
    let(:item) do
      CredStash::Repository::Item.new(
        name: 'name',
        version: "%019d" % 1,
        key: 'base64_encoded_key',
        contents: 'base64_encoded_contents',
        hmac: 'hmac'
      )
    end

    it 'puts item to DynamoDB' do
      put_params = {
        table_name:  'credential-store',
        item: {
          name: item.name,
          version: item.version,
          key: item.key,
          contents: item.contents,
          hmac: item.hmac
        },
        condition_expression: "attribute_not_exists(#name)",
        expression_attribute_names: { "#name" => "name" },
      }

      stub_client = double
      expect(stub_client).to receive(:put_item).with(put_params)
      described_class.new(client: stub_client).put(item)
    end

    context 'with table_name option' do
      before do
        CredStash.configure do |config|
          config.table_name = 'awesome_table'
        end
      end

      after do
        CredStash.config.reset!
      end

      it 'puts item to DynamoDB' do
        put_params = {
          table_name: 'awesome_table',
          item: {
            name: item.name,
            version: item.version,
            key: item.key,
            contents: item.contents,
            hmac: item.hmac
          },
          condition_expression: "attribute_not_exists(#name)",
          expression_attribute_names: { "#name" => "name" },
        }

        stub_client = double
        expect(stub_client).to receive(:put_item).with(put_params)
        described_class.new(client: stub_client).put(item)
      end
    end
  end

  describe '#list' do
    let(:stub_client) do
      Aws::DynamoDB::Client.new(
        stub_responses: { scan: { items: items } }
      )
    end

    let(:items) do
      [{ 'name' => 'name', 'version' => '0000001' }]
    end

    it 'returns items' do
      items = described_class.new(client: stub_client).list
      expect(items.size).to eq 1

      item = items.first
      expect(item.name).to eq 'name'
      expect(item.version).to eq '0000001'
    end

    context 'pagination' do
      let(:item1) { { 'name' => 'abc', 'version' => '0000001' } }
      let(:item2) { { 'name' => 'def', 'version' => '0000002' } }

      before do
        stub_client.stub_responses(:scan, -> (context) {
          if context.params[:exclusive_start_key].nil?
            { items: [item1], last_evaluated_key: item1 }
          else
            { items: [item2] }
          end
        })
      end

      it 'returns items' do
        items = described_class.new(client: stub_client).list
        expect(items.size).to eq 2

        item = items[0]
        expect(item.name).to eq 'abc'
        expect(item.version).to eq '0000001'

        item = items[1]
        expect(item.name).to eq 'def'
        expect(item.version).to eq '0000002'
      end
    end
  end

  describe '#select' do
    let(:stub_client) do
      Aws::DynamoDB::Client.new(
        stub_responses: { query: { items: items } }
      )
    end

    let(:items) do
      [{ 'name' => 'name', 'version' => 'version' }]
    end

    it 'returns item' do
      items = described_class.new(client: stub_client).select('name')
      expect(items.size).to eq 1
      expect(items.first.name).to eq 'name'
    end
  end

  describe '#delete' do
    let(:item) do
      CredStash::Repository::Item.new(name: 'name', version: '0001')
    end

    it 'deletes from DynamoDB' do
      stub_client = double
      expect(stub_client).to receive(:delete_item).with(
                               table_name:  'credential-store',
                               key: {
                                 name: 'name',
                                 version: '0001'
                               }
                             )
      described_class.new(client: stub_client).delete(item)
    end
  end
end
