module SmallWonder
  class Configuratorator

    def self.generate_and_upload_files(application, path, opts = {})
      file_list = generate_files(application, path, opts)
      upload_files(application)
      apply_files(application, path, opts)
      file_list
    end

    def self.generate_files(application, path, opts = {})
      config_template_dir = "#{SmallWonder::Config.application_templates_dir}/#{application.application_name}"

      templates = Dir["#{config_template_dir}/**/*.erb"]

      file_list = []

      templates.each do |file|
        begin
          filename = File.basename(file, '.*')
          filename.gsub!("VERSION", application.version)

          reldir = File.dirname(file).gsub("#{config_template_dir}", ".")
          reldir.gsub!("VERSION", application.version)
        rescue Exception => e
          SmallWonder::Log.fatal("Something went badly attempting to replace VERSION with the version number, likely missing version data.\nerror: #{e}")
          exit(1)
        end

        file_list << "#{reldir}/#{filename}"

        SmallWonder::Log.info("Generating #{reldir}/#{filename}")

        generated_file = generate_file(file, application, config_template_dir, opts)

        file_dir = "#{SmallWonder::Config.config_template_working_directory}/#{application.node_name}/#{application.application_name}/#{reldir}"

        FileUtils.mkdir_p(file_dir)

        SmallWonder::Utils.write_file(generated_file, "#{file_dir}/#{filename}")
      end

      file_list
    end

    def self.upload_files(application)
      Net::SSH.start(application.node_name, SmallWonder::Config.ssh_user) do |ssh|
        ssh.exec!("mkdir -p #{SmallWonder::Config.remote_working_dir}")
      end

      Net::SCP.start(application.node_name, SmallWonder::Config.ssh_user) do |scp|
        scp.upload!("#{SmallWonder::Config.config_template_working_directory}/#{application.node_name}/#{application.application_name}", SmallWonder::Config.remote_working_dir, {:recursive => true})
      end
    end

    def self.apply_files(application, path, opts = {})
      copy_files_to_install_dir(application.node_name, application.application_name, path)

      if opts[:no_cleanup]
        cleanup_working_directories(application.node_name, application.application_name)
      end
    end

    private

    def self.generate_file(file, application, config_template_dir, opts)
      @deploy_config = application.config_data
      @options = @deploy_config
      @node = Chef::Node.load(application.node_name)
      node = Chef::Node.load(application.node_name)

      if opts[:app_options]
        @app_options = opts[:app_options]
      end

      template_file = File.read(file)

      begin
        template = ERB.new(template_file)
      rescue Exception => e
        SmallWonder::Log.error("Error generating file (#{file}).")
        SmallWonder::Log.error(e)
        exit(1)
      end

      template.result(binding)
    end

    def self.copy_files_to_install_dir(node_name, application, path)
      Net::SSH.start(node_name, SmallWonder::Config.ssh_user) do |ssh|
        ssh.exec!("echo \"#{SmallWonder::Config.sudo_password}\n\" | sudo -S cp -Rf #{SmallWonder::Config.remote_working_dir}/#{application}/* /#{path}/")
      end
    end

    def self.cleanup_working_directories(node_name, application)
      FileUtils.rm_rf("#{SmallWonder::Config.config_template_working_directory}/#{node_name}/#{application}")

      Net::SSH.start(node_name, SmallWonder::Config.ssh_user) do |ssh|
        ssh.exec!("rm -rf #{SmallWonder::Config.remote_working_dir}")
      end
    end

  end
end
