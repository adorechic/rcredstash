require 'spec_helper'

describe CredStash::CipherKey do
  describe '.generate' do
    it 'generates new key' do
      stub_client = Aws::KMS::Client.new(
        stub_responses: {
          generate_data_key: {
            plaintext: '0' * 32 + '1' * 32,
            ciphertext_blob: 'ciphertext_blob'
          }
        }
      )

      key = described_class.generate(client: stub_client)
      expect(key.data_key).to eq '0' * 32
      expect(key.hmac_key).to eq '1' * 32
      expect(key.wrapped_key).to eq 'ciphertext_blob'
    end
  end

  describe '.decrypt' do
    it 'decrypts key' do
      stub_client = Aws::KMS::Client.new(
        stub_responses: {
          decrypt: {
            plaintext: '0' * 32 + '1' * 32,
          }
        }
      )
      key = described_class.decrypt('ciphertext_blob', client: stub_client)
      expect(key.data_key).to eq '0' * 32
      expect(key.hmac_key).to eq '1' * 32
      expect(key.wrapped_key).to eq 'ciphertext_blob'
    end
  end

  describe '#hmac' do
    let(:key) { described_class.new(hmac_key: '0', data_key: '0', wrapped_key: '0') }

    it 'creates HMAC of SHA256' do
      expect(key.hmac('1')).to eq OpenSSL::HMAC.hexdigest("SHA256", '0', '1')
    end
  end

  describe '#encrypt #decrypt' do
    let(:key) { described_class.new(hmac_key: '0', data_key: '0' * 32, wrapped_key: '0') }
    let(:message) { 'message' }

    it do
      encrypted = key.encrypt(message)
      expect(encrypted).to be_a(String)
      expect(encrypted).to_not eq message

      expect(key.decrypt(encrypted)).to eq message

      another_key = described_class.new(hmac_key: '0', data_key: '1' * 32, wrapped_key: '0')
      expect(another_key.decrypt(encrypted)).to_not eq message
    end
  end
end
