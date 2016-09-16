module CredStash
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Config.new
    end
  end

  class Config
    attr_accessor :table_name, :storage

    def initialize
      reset!
    end

    def reset!
      @table_name = 'credential-store'
      @storage = :dynamodb
    end
  end
end
