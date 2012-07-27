module SmallWonder
  class CLI
    include Mixlib::CLI

    option :config_file,
      :short => "-c CONFIG",
      :long  => "--config CONFIG",
      :default => "#{ENV['HOME']}/.small_wonder/small_wonder.rb",
      :description => "The configuration file to use"

    option :knife_config_file,
      :short => "-k CONFIG",
      :long  => "--knife CONFIG",
      :default => "#{ENV['HOME']}/.chef/knife.rb",
      :description => "The knife configuration file to use"

    option :action,
      :short => "-a ACTION",
      :long  => "--action ACTION",
      :description => "The action you want small wonder to take [deploy]",
      :default => "none"

    option :app,
      :short => "-p APP",
      :long  => "--app APP",
      :description => "The app you want small wonder to do something with",
      :default => nil

    option :version,
      :short => "-V VERSION",
      :long  => "--version VERSION",
      :description => "The version of app you want small wonder to do something with",
      :default => nil

    option :query,
      :short => "-q query",
      :long  => "--query query",
      :description => "The query you want small wonder to do something with",
      :default => nil

    option :write_node_file,
      :short => "-w",
      :long  => "--write",
      :description => "true/false write the node json file to your chef-repo at end of deploy",
      :default => false

    option :log_level,
      :short => "-l LEVEL",
      :long  => "--log_level LEVEL",
      :description => "Set the log level (debug, info, warn, error, fatal)",
      :default => :info,
      :proc => Proc.new { |l| l.to_sym }

    option :help,
      :short => "-h",
      :long => "--help",
      :description => "All the help you need ...",
      :on => :tail,
      :boolean => true,
      :show_options => true,
      :exit => 0

  end
end