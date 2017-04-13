require 'thor'

module CredStash
  class CLI < Thor
    desc "get [key name]", "Show a value for key name"
    def get(name)
      puts CredStash.get(name)
    end

    desc "put [key name]", "Put a value for key name"
    def put(name)
      value = Readline.readline("secret value> ")
      CredStash.put(name, value)
      puts "#{name} has stored."
    end

    desc "list", "Show all stored keys"
    def list
      puts CredStash.list.keys
    end

    desc "delete [key name]", "Delete a key"
    def delete(name)
      CredStash.delete(name)
      puts "#{name} has deleted."
    end

    desc "setup", "Setup credstash repository on DynamoDB"
    def setup
      CredStash.setup
      puts "Set up successfully"
    end
  end
end
