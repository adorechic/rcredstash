class CredStash::Repository
  class Item
    attr_reader :key, :contents

    def initialize(key:, contents:)
      @key = key
      @contents = contents
    end
  end

  class DynamoDB
    def initialize(client: nil)
      @client = client || Aws::DynamoDB::Client.new
    end

    def get(name)
      res = @client.query(
        table_name:  'credential-store',
        limit: 1,
        consistent_read: true,
        scan_index_forward: false,
        key_condition_expression: "#name = :name",
        expression_attribute_names: { "#name" => "name"},
        expression_attribute_values: { ":name" => name }
      )
      material = res.items.first
      Item.new(key: material["key"], contents: material["contents"])
    end
  end

  def self.default_storage
    DynamoDB.new
  end

  def initialize(storage: Repository.default_storage)
    @storage = storage
  end

  def get(name)
    @storage.get(name)
  end
end
