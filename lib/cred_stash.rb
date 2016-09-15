require 'aws-sdk'

module CredStash
  class << self
    def get(name)
      secret = Secret.find(name)

      if secret.falsified?
        raise "Invalid secret. #{name} has falsified"
      end

      secret.decrypted_value

    rescue CredStash::ItemNotFound
      nil
    end

    def put(name, value)
      secret = Secret.new(name: name, value: value)
      secret.encrypt!
      secret.save
    end

    def list
      Repository.instance.list.inject({}) {|h, item| h[item.name] = item.version; h }
    end

    def delete(name)
      # TODO needs delete target version option
      repository = Repository.instance
      item = repository.select(name).first
      repository.delete(item)
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
