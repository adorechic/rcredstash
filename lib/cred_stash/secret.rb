class CredStash::Secret
  attr_reader :name, :value, :key, :encrypted_value, :hmac

  def initialize(name:, value: nil, key: nil, encrypted_value: nil, hmac: nil, context: {})
    @name = name
    @value = value
    @key = key
    @encrypted_value = encrypted_value
    @hmac = hmac
    @context = context
  end

  def encrypt!(kms_key_id: nil)
    @key = CredStash::CipherKey.generate(kms_key_id: kms_key_id, context: @context)
    @encrypted_value = @key.encrypt(@value)
    @hmac = @key.hmac(@encrypted_value)
  end

  def save
    self.class.repository.put(to_item)
  end

  def falsified?
    @key.hmac(@encrypted_value) == @hmac
  end

  def decrypted_value
    @key.decrypt(@encrypted_value)
  end

  class << self
    def find(name, context: {}, version: nil)
      item = repository.get(name, version: version)
      new(
        name: name,
        key: CredStash::CipherKey.decrypt(Base64.decode64(item.key), context: context),
        encrypted_value: Base64.decode64(item.contents),
        hmac: item.hmac
      )
    end

    def repository
      CredStash::Repository.instance
    end
  end


  private

  def to_item
    CredStash::Repository::Item.new(
      name: name,
      version: "%019d" % (current_version + 1),
      key: Base64.encode64(key.wrapped_key),
      contents: Base64.encode64(encrypted_value),
      hmac: hmac
    )
  end

  def current_version
    item = CredStash::Repository.instance.select(name, pluck: 'version', limit: 1).first
    if item
      item.version.to_i
    else
      0
    end
  end
end
