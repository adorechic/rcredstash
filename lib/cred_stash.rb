require 'aws-sdk'

module CredStash
  class << self
    def get(name)
      item = Repository.new.get(name)
      wrapped_key = Base64.decode64(item.key)
      contents = Base64.decode64(item.contents)

      key = CipherKey.decrypt(wrapped_key)

      unless key.hmac(contents) == item.hmac
        raise "invalid"
      end

      key.decrypt(contents)
    end

    def put(name, value)
      secret = Secret.new(name: name, value: value)
      secret.encrypt!
      secret.save
    end

    def list
      Repository.new.list.inject({}) {|h, item| h[item.name] = item.version; h }
    end

    def delete(name)
      # TODO needs delete target version option
      repository = Repository.new
      item = repository.select(name).first
      repository.delete(item)
    end

    private

    def get_highest_version(name)
      item = Repository.new.select(name, pluck: 'version', limit: 1).first
      if item
        item.version.to_i
      else
        0
      end
    end
  end
end

require 'cred_stash/cipher_key'
require 'cred_stash/cipher'
require 'cred_stash/error'
require 'cred_stash/repository'
require 'cred_stash/secret'
