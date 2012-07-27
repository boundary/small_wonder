role :example do
  task :deploy do # deploy is the default initial task called
    example.tasknumberone
    example.templatestuff
    example.applicationstuff
    example.chefstuff
  end

  task :tasknumberone do
    begin
      ls "-al", "/some/path", :echo => true
    rescue
      log "werid ls didn't work."
    end
  end

  task :templatestuff do
    # generate and update the template files
    SmallWonder::Configuratorator.generate_and_upload_files(application, "/opt/example") # pass it the application object and the path
    #SmallWonder::Configuratorator.generate_and_upload_files(application, base_path, {:app_options => "someotherdata"})
  end

  task :applicationstuff do
    log "#{application.config_data["databaghash"]}" # log some databag data
    log "#{application.version}"
    log "#{application.application_name}"
    log "#{application.node_name}"
    log "#{application.status}" # current status (automatically set to task name)

    # maybe you want to set the version and status during deployment youself
    application.version = "123"
    application.status = "just set the version"
  end

  task :chefstuff do
    data = Chef::Node.load(application.node_name)
    log "This is some deep chef shit, cpu0 model #{data["cpu"]["0"]["model_name"]}"

    log "example is deployed to:"
    Chef::Search::Query.new.search(:node, "deployed_applications:example") do |n|
      log "*  #{n[:fqdn]}"
    end
  end
end