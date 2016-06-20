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
end
