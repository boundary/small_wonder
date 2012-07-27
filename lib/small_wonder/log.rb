module SmallWonder
  require 'colorize'

  class Log
    COLORS = {
      'FATAL' => :light_red,
      'ERROR' => :light_red,
      'WARN' => :light_yellow,
      'INFO' => nil,
      'DEBUG' => :light_blue
    }

    class Formatter < Mixlib::Log::Formatter
      def call(severity, time, progname, msg)
        str = format("[%s] %s\n",
                     time.strftime("%H:%M:%S"),
                     msg).colorize(COLORS[severity])
      end
    end

    extend Mixlib::Log

    def self.init(*opts)
      super *opts

      @logger.formatter = Formatter.new() if @logger.respond_to?(:formatter=)
      @logger
    end
  end
end
