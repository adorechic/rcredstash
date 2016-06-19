require 'spec_helper'

describe CredStash::Cipher do
  let(:key) { '0' * 32 }
  let(:input) { 'value' }

  it 'encrypts and decrypts by AES-256 CTR mode'do
    encrypted = CredStash::Cipher.new(key).encrypt(input)
    expect(encrypted).to be_a(String)
    expect(encrypted).to_not eq input

    decrypted = CredStash::Cipher.new(key).decrypt(encrypted)
    expect(decrypted).to eq input
  end
end
