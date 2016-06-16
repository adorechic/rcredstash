require 'aws-sdk'

module CredStash
  def self.get(name)
    dynamodb = Aws::DynamoDB::Client.new
    res = dynamodb.query(
      table_name:  'credential-store',
      limit: 1,
      consistent_read: true,
      scan_index_forward: false,
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

  def self.put(name, value)
    kms = Aws::KMS::Client.new
    kms_res = kms.generate_data_key(key_id: 'alias/credstash', number_of_bytes: 64)
    data_key = kms_res.plaintext[0..32]
    hmac_key = kms_res.plaintext[32..-1]
    wrapped_key = kms_res.ciphertext_blob

    cipher = OpenSSL::Cipher::AES.new(256, "CTR")
    cipher.encrypt
    cipher.key = data_key
    # FIXME It is better to generate and store initial counter
    cipher.iv = %w(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1).map(&:hex).pack('C' * 16)
    contents = cipher.update(value) + cipher.final

    hmac = OpenSSL::HMAC.hexdigest("sha256", hmac_key, contents)

    dynamodb = Aws::DynamoDB::Client.new
    dynamodb.put_item(
      table_name:  'credential-store',
      item: {
        name: name,
        version: "%019d" % 1, # TODO Check previous highest version
        key: Base64.encode64(wrapped_key),
        contents: Base64.encode64(contents),
        hmac: hmac
      },
      condition_expression: "attribute_not_exists(#name)",
      expression_attribute_names: { "#name" => "name" },
    )
  end

  def self.list
    dynamodb = Aws::DynamoDB::Client.new
    res = dynamodb.scan(
      table_name:  'credential-store',
      projection_expression: '#name, version',
      expression_attribute_names: { "#name" => "name" },
    )
    res.items.inject({}) {|h, i| h[i['name']] = i['version']; h }
  end

  def self.delete(name)
    dynamodb = Aws::DynamoDB::Client.new
    res = dynamodb.query(
      table_name:  'credential-store',
      consistent_read: true,
      key_condition_expression: "#name = :name",
      expression_attribute_names: { "#name" => "name"},
      expression_attribute_values: { ":name" => name }
    )
    # TODO needs delete target version option

    item = res.items.first
    dynamodb.delete_item(
      table_name:  'credential-store',
      key: {
        name: item['name'],
        version: item['version'],
      }
    )
  end
end
