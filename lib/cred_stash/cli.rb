require 'thor'

module CredStash
  class CLI < Thor
    desc "get [key name]", "Show a value for key name"
    option :version, type: :string, aliases: '-v', desc: 'Show a value for key name with their versions'
    def get(name)
      puts CredStash.get(name, version: options[:version])
    end

    desc "put [key name]", "Put a value for key name"
    option :kms_key_id , :desc => "the KMS key-id of the master key to use. Defaults to alias/credstash"
    def put(name)
      value = Readline.readline("secret value> ")
      kms_key_id = options[:kms_key_id] if options[:kms_key_id]
      CredStash.put(name, value, kms_key_id: kms_key_id)
      puts "#{name} has stored."
    end

    desc "list", "Show all stored keys"
    option :version, type: :boolean, aliases: '-v', desc: 'Show all stored keys with their versions'
    def list()
      if options[:version]
        CredStash.list_with_version.each do |hash|
          puts "#{hash["name"]} --version: #{hash["version"]}"
        end
      else
        puts CredStash.list.keys
      end
    end

    desc "delete [key name]", "Delete a key"
    option :version, type: :string, aliases: '-v', desc: 'Specify version'
    def delete(name)
      CredStash.delete(name, version: options[:version])
      puts "#{name} has deleted."
    end

    desc "setup", "Setup credstash repository on DynamoDB"
    def setup
      CredStash.setup
      puts "Set up successfully"
    end
  end
end
