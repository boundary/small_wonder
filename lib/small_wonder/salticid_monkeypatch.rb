class ::Salticid::Host
  def application
    @application
  end

  def application=(app)
    @application = app
  end
end

class Salticid::Task
  alias_method :stock_run, :run

  def run(context = nil, *args)
    if context.respond_to? :application
      context.application.status = name
    end

    SmallWonder::Log.info("Running task: #{name}")
    stock_run(context, *args)
  end
end