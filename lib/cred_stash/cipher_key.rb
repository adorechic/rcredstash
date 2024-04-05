require 'aws-sdk-kms'

class CredStash::CipherKey
  DEFAULT_KMS_KEY_ID = "alias/credstash".freeze

  attr_reader :data_key, :hmac_key, :wrapped_key

  def self.generate(client: CredStash.config.kms_client, kms_key_id: nil,
                    context: {})
    res = client.generate_data_key(
      key_id: kms_key_id || DEFAULT_KMS_KEY_ID,
      number_of_bytes: 64,
      encryption_context: context
    )
    new(
      data_key: res.plaintext[0...32],
      hmac_key: res.plaintext[32..-1],
      wrapped_key: res.ciphertext_blob
    )
  end

  def self.decrypt(wrapped_key, client: CredStash.config.kms_client, context: {})
    res = client.decrypt(ciphertext_blob: wrapped_key, encryption_context: context)
    new(
      data_key: res.plaintext[0...32],
      hmac_key: res.plaintext[32..-1],
      wrapped_key: wrapped_key
    )
  end

  def initialize(data_key:, hmac_key:, wrapped_key:)
    @data_key = data_key
    @hmac_key = hmac_key
    @wrapped_key = wrapped_key
  end

  def hmac(message)
    OpenSSL::HMAC.hexdigest("SHA256", hmac_key, message)
  end

  def encrypt(message)
    CredStash::Cipher.new(data_key).encrypt(message)
  end

  def decrypt(message)
    CredStash::Cipher.new(data_key).decrypt(message)
  end
end
