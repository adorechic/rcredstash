module CredStash
  class << self
    def get(name, context: {}, raise_if_missing: false, version: nil)
      secret = Secret.find(name, context: context, version: version)

      if secret.falsified?
        raise "Invalid secret. #{name} has falsified"
      end

      secret.decrypted_value

    rescue CredStash::ItemNotFound => e
      raise e if raise_if_missing
      nil
    end

    def put(name, value, kms_key_id: nil, context: {})
      secret = Secret.new(name: name, value: value, context: context)
      secret.encrypt!(kms_key_id: kms_key_id)
      secret.save
    end

    def list
      Repository.instance.list.inject({}) {|h, item| h[item.name] = item.version; h }
    end

    def list_with_version
      Repository.instance.list.inject([]) do |h, item|
        h.push({
          "name" => item.name,
          "version" => item.version
        })
      end
    end

    def delete(name, version: nil)
      repository = Repository.instance
      item = repository.select(name, version: version).first
      repository.delete(item)
    end

    def setup
      Repository.instance.setup
    end

    private

    def get_highest_version(name)
      item = Repository.instance.select(name, pluck: 'version', limit: 1).first
      if item
        item.version.to_i
      else
        0
      end
    end
  end
end

require 'cred_stash/config'
require 'cred_stash/cipher_key'
require 'cred_stash/cipher'
require 'cred_stash/error'
require 'cred_stash/repository'
require 'cred_stash/secret'
