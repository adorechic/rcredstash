require 'aws-sdk'
module CredStash
  def self.get
    dynamodb = Aws::DynamoDB::Client.new
    res = dynamodb.query(
      table_name:  'credential-store',
      limit: 1,
      consistent_read: true,
      scan_index_forward: true,
      key_condition_expression: "#name = :name",
      expression_attribute_names: { "#name" => "name"},
      expression_attribute_values: { ":name" => "myapp2.db.pass"}
    )
    material = res.items.first
    data = Base64.decode64(material["key"])
    contents = Base64.decode64(material["contents"])

    kms = Aws::KMS::Client.new
    kms_res = kms.decrypt(ciphertext_blob: data)

    return kms_res

    key = kms_res.plaintext[0..32]
    hmackey = kms_res.plaintext[32..-1]

    unless OpenSSL::HMAC.hexdigest("sha256", hmackey, contents) == material["hmac"]
      raise "invalid"
    end

    return key, contents

    cipher = OpenSSL::Cipher::AES.new(128, "CTR")
    cipher.decrypt
    cipher.key = key
    cipher.iv = "00000000000000000000000000000001".unpack('a2'*16).map{ |x| x.hex }.pack('C'*16)
    cipher.update(contents) + cipher.final
  end
end
