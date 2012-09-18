module SmallWonder
  class Utils

    def self.consume_config_file(cli, file)
      if File.exists?(file)
        SmallWonder::Config.from_file(file)
        SmallWonder::Config.merge!(cli.config)

        SmallWonder::Log.level(SmallWonder::Config.log_level)
      else
        SmallWonder::Log.error("#{file} doesn't exist!")
        exit(1)
      end
    end

    def self.write_node_data_file(node)
      data = Chef::Node.load(node)

      file = "#{SmallWonder::Config.chef_repo_path}/nodes/#{node}.json"

      SmallWonder::Log.info("Writing node file (#{file}).")

      write_file(JSON.pretty_generate(data), file)
    end

  end
end