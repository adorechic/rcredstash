require 'openssl'

class CredStash::Cipher
  def initialize(key)
    @key = key
  end

  def encrypt(value)
    run(mode: :encrypt, value: value)
  end

  def decrypt(value)
    run(mode: :decrypt, value: value).force_encoding("UTF-8")
  end

  private

  def run(mode:, value:)
    cipher = OpenSSL::Cipher::AES.new(256, "CTR")

    case mode
    when :encrypt
      cipher.encrypt
    when :decrypt
      cipher.decrypt
    else
      raise ArgumentError, "Unknown mode: #{mode}"
    end

    cipher.key = @key
    # FIXME It is better to generate and store initial counter
    cipher.iv = %w(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1).map(&:hex).pack('C' * 16)
    cipher.update(value) + cipher.final
  end
end
