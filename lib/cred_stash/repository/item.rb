module CredStash::Repository
  class Item
    attr_reader :key, :contents, :name, :version, :hmac

    def initialize(key: nil, contents: nil, name: nil, version: nil, hmac: nil)
      @key = key
      @contents = contents
      @name = name
      @version = version
      @hmac = hmac
    end
  end
end
