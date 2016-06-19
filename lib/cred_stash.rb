require 'aws-sdk'

module CredStash
  class << self
    def get(name)
      item = Repository.new.get(name)
      data = Base64.decode64(item.key)
      contents = Base64.decode64(item.contents)

      kms = Aws::KMS::Client.new
      kms_res = kms.decrypt(ciphertext_blob: data)

      key = kms_res.plaintext[0..32]
      hmackey = kms_res.plaintext[32..-1]

      unless OpenSSL::HMAC.hexdigest("sha256", hmackey, contents) == material["hmac"]
        raise "invalid"
      end

      Cipher.new(key).decrypte(contents)
    end

    def put(name, value)
      kms = Aws::KMS::Client.new
      kms_res = kms.generate_data_key(key_id: 'alias/credstash', number_of_bytes: 64)
      data_key = kms_res.plaintext[0..32]
      hmac_key = kms_res.plaintext[32..-1]
      wrapped_key = kms_res.ciphertext_blob

      contents = Cipher.new(data_key).encrypt(value)

      hmac = OpenSSL::HMAC.hexdigest("sha256", hmac_key, contents)

      version = get_highest_version(name) + 1

      item = Repository::Item.new(
        name: name,
        version: "%019d" % version,
        key: Base64.encode64(wrapped_key),
        contents: Base64.encode64(contents),
        hmac: hmac
      )
      Repository.new.put(item)
    end

    def list
      dynamodb = Aws::DynamoDB::Client.new
      res = dynamodb.scan(
        table_name:  'credential-store',
        projection_expression: '#name, version',
        expression_attribute_names: { "#name" => "name" },
      )
      res.items.inject({}) {|h, i| h[i['name']] = i['version']; h }
    end

    def delete(name)
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

    private

    def get_highest_version(name)
      dynamodb = Aws::DynamoDB::Client.new
      res = dynamodb.query(
        table_name:  'credential-store',
        limit: 1,
        consistent_read: true,
        scan_index_forward: false,
        key_condition_expression: "#name = :name",
        expression_attribute_names: { "#name" => "name"},
        expression_attribute_values: { ":name" => name },
        projection_expression: 'version',
      )

      item = res.items.first

      if item
        item['version'].to_i
      else
        0
      end
    end
  end
end

require 'cred_stash/cipher'
require 'cred_stash/error'
require 'cred_stash/repository'
