require 'spec_helper'

describe CredStash::Secret do
  describe '#encrypt!' do
    it 'encrypts value' do
      secret = described_class.new(name: 'name', value: 'value')
      key = double(encrypt: 'encrypted_value', hmac: 'hmac')
      expect(CredStash::CipherKey).to receive(:generate).and_return(key)

      secret.encrypt!

      expect(secret.key).to eq key
      expect(secret.encrypted_value).to eq 'encrypted_value'
      expect(secret.hmac).to eq 'hmac'
    end
  end

  describe '#save' do
    let(:stub_client) do
      Aws::DynamoDB::Client.new(
        stub_responses: { query: { items: [{ 'version' => '0000000000000000002' }] } }
      )
    end

    let(:storage) do
      CredStash::Repository::DynamoDB.new(client: stub_client)
    end

    let(:secret) do
      described_class.new(
        name: 'name',
        value: 'value',
        key: double(wrapped_key: 'key'),
        encrypted_value: 'encrypted_value',
        hmac: 'hmac'
      )
    end

    before do
      allow(CredStash::Repository).to receive(:default_storage).and_return(storage)
    end

    it 'saves item' do
      expect(storage).to receive(:put) do |item|
        expect(item.name).to eq 'name'
        expect(item.version).to eq '0000000000000000003'
        expect(item.key).to eq Base64.encode64('key')
        expect(item.contents).to eq Base64.encode64('encrypted_value')
        expect(item.hmac).to eq 'hmac'
      end

      secret.save
    end
  end
end
