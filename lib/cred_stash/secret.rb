class CredStash::Secret
  attr_reader :name, :value, :key, :encrypted_value, :hmac

  def initialize(name:, value:, key: nil, encrypted_value: nil, hmac: nil)
    @name = name
    @value = value
    @key = key
    @encrypted_value = encrypted_value
    @hmac = hmac
  end

  def encrypt!
    @key = CredStash::CipherKey.generate
    @encrypted_value = @key.encrypt(@value)
    @hmac = @key.hmac(@encrypted_value)
  end

  def save
    CredStash::Repository.new.put(to_item)
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
    item = CredStash::Repository.new.select(name, pluck: 'version', limit: 1).first
    if item
      item.version.to_i
    else
      0
    end
  end
end
