require 'aws-sdk'
module CredStash
  def self.get(name)
    dynamodb = Aws::DynamoDB::Client.new
    res = dynamodb.query(
      table_name:  'credential-store',
      limit: 1,
      consistent_read: true,
      scan_index_forward: true,
      key_condition_expression: "#name = :name",
      expression_attribute_names: { "#name" => "name"},
      expression_attribute_values: { ":name" => name }
    )
    material = res.items.first
    data = Base64.decode64(material["key"])
    contents = Base64.decode64(material["contents"])

    kms = Aws::KMS::Client.new
    kms_res = kms.decrypt(ciphertext_blob: data)

    key = kms_res.plaintext[0..32]
    hmackey = kms_res.plaintext[32..-1]

    unless OpenSSL::HMAC.hexdigest("sha256", hmackey, contents) == material["hmac"]
      raise "invalid"
    end

    cipher = OpenSSL::Cipher::AES.new(256, "CTR")
    cipher.decrypt
    cipher.key = key
    # FIXME It is better to generate and store initial counter
    cipher.iv = %w(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1).map(&:hex).pack('C' * 16)
    value = cipher.update(contents) + cipher.final
    value.force_encoding("UTF-8")
  end
end
