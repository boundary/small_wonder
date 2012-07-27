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

    def self.write_file(data, path)
      begin
        file = File.new(path,"w")
        file.puts data
      rescue Exception => e
        SmallWonder::Log.error("Error writing file (#{path}).")
        SmallWonder::Log.error(e)
        exit(1)
      ensure
        file.close
      end
    end

    def self.sane_working_dir?(dir)
      sane = []
      sane << starts_with?(dir, "/tmp/small_wonder")

      if dir.include?("..")
        sane << false
      else
        sane << true
      end

      if sane.include?(false)
        false
      else
        true
      end
    end

    def self.starts_with?(string, prefix)
      prefix = prefix.to_s
      string[0, prefix.length] == prefix
    end

  end
end