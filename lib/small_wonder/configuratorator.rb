module SmallWonder
  class Configuratorator

    def self.generate_and_upload_files(application, path, opts = {})
      config_template_dir = "#{SmallWonder::Config.application_templates_dir}/#{application.application_name}"

      templates = Dir["#{config_template_dir}/**/*.erb"]

      file_list = []

      templates.each do |file|
        filename = File.basename(file, '.*')
        filename.gsub!("VERSION", application.version)

        reldir = File.dirname(file).gsub("#{config_template_dir}", ".")
        reldir.gsub!("VERSION", application.version)

        file_list << "#{reldir}/#{filename}"

        SmallWonder::Log.info("Generating #{reldir}/#{filename}")

        generated_file = generate_file(file, application, config_template_dir, opts)

        file_dir = "#{SmallWonder::Config.config_template_working_directory}/#{application.application_name}/#{reldir}"

        FileUtils.mkdir_p(file_dir)

        SmallWonder::Utils.write_file(generated_file, "#{file_dir}/#{filename}")
      end

      upload_files(application.node_name, application.application_name)
      copy_files_to_install_dir(application.node_name, application.application_name, path)
      cleanup_working_directories(application.node_name, application.application_name)

      file_list
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

    def self.upload_files(node_name, application)
      Net::SSH.start(node_name, SmallWonder::Config.ssh_user) do |ssh|
        ssh.exec!("mkdir -p #{SmallWonder::Config.remote_working_dir}")
      end

      Net::SCP.start(node_name, SmallWonder::Config.ssh_user) do |scp|
        scp.upload!("#{SmallWonder::Config.config_template_working_directory}/#{application}", SmallWonder::Config.remote_working_dir, {:recursive => true})
      end
    end

    def self.copy_files_to_install_dir(node_name, application, path)
      Net::SSH.start(node_name, SmallWonder::Config.ssh_user) do |ssh|
        ssh.exec!("echo \"#{@sudo_password}\n\" | sudo -S cp -R #{SmallWonder::Config.remote_working_dir}/#{application}/* /#{path}/")
      end
    end

    def self.cleanup_working_directories(node_name, application)
      FileUtils.rm_rf("#{SmallWonder::Config.config_template_working_directory}/#{application}")

      Net::SSH.start(node_name, SmallWonder::Config.ssh_user) do |ssh|
        ssh.exec!("rm -rf #{SmallWonder::Config.remote_working_dir}")
      end
    end

  end
end