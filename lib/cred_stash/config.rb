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
    attr_accessor :table_name, :storage, :kms_client, :dynamo_client

    def initialize
      reset!
    end

    def reset!
      @table_name = 'credential-store'
      @storage = :dynamodb
      @kms_client = Aws::KMS::Client.new
      @dynamo_client = Aws::DynamoDB::Client.new
    end
  end
end
