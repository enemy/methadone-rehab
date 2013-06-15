require 'base_test'
require 'methadone'
require 'stringio'
require 'fileutils'

class TestMulti < BaseTest
  include Methadone::Main
  include Methadone::CLILogging

  module Commands
    class Walk
      include Methadone::Main
      include Methadone::CLILogging
      main do |distance|
        puts "walk called"
      end
      options[:direction] = 0
      description "moves slowly for a given distance"
      on '-s', '--silly-walk'
      on '-d', '--direction DIRECTION', Integer, "Compass cardinal direction"
      arg "distance", "How far to walk"
    end
    class Run
      include Methadone::Main
      include Methadone::CLILogging
      main do |distance, duty_cycle|
        puts "run called"
      end
      options[:direction] = 0
      description "moves quickly for a given distance"
      on '-s', '--silly-walk'
      on '-d', '--direction DIRECTION', Integer, "Compass cardinal direction"
      arg "distance", "How far to run"
      arg "duty_cycle", "Percent of time spent running (default: 100)", :optional
    end
    class Greet
      include Methadone::Main

      options[:lang] = 'es'

      main do 
        case options[:lang]
        when 'en'
          puts 'Hello'
        when 'fr'
          puts 'Bonjour'
        when 'es'
          puts 'Hola'
        else
          puts '????'
        end
      end
    end
  end

  def setup
    @original_argv = ARGV.clone
    ARGV.clear
    @old_stdout = $stdout
    $stdout = StringIO.new
    @logged = StringIO.new
    @orig_logger = logger
    @custom_logger = Logger.new(@logged)
    change_logger @custom_logger

    @original_home = ENV['HOME']
    fake_home = '/tmp/fake-home'
    FileUtils.rm_rf(fake_home)
    FileUtils.mkdir(fake_home)
    ENV['HOME'] = fake_home
  end

  def teardown
    @commands = nil
    change_logger @orig_logger
    set_argv @original_argv
    ENV.delete('DEBUG')
    ENV.delete('APP_OPTS')
    $stdout = @old_stdout
    ENV['HOME'] = @original_home
  end

  test_that "commands can be specified" do
    When {
      command "walk" => Commands::Walk
    }
    Then number_of_commands_should_be(1)
    Then commands_should_include("walk")
    Then {
      provider_for_command("walk").should be Commands::Walk
    }
  end

  test_that "command providers must accept go! message" do
    Given {
      module Commands
        class WontWork
        end
      end
    }
    When {
      @error = nil
      begin
        command "trythis" => Commands::WontWork
      rescue Exception => error
        @error = error
      end
    }
    Then number_of_commands_should_be(0)
    Then {
      expect(@error).to be_a_kind_of(::Methadone::InvalidProvider)
    }
  end

  test_that "command is detected in the arguments" do
    Given {
      main do
      end

      command "walk" => Commands::Walk
      set_argv %w(walk 10)
    }
    When run_go_safely
    Then {
      expect(opts.selected_command).to eq('walk')
    }
  end

  test_that "command in the arguments causes the right command to be called" do
    Given app_has_subcommands('walk','run')
    And {
      version '1.2.3'
      set_argv %w(walk 10)
    }
    When run_go_safely
    Then {
      expect(opts.command_names).to include('walk')
      expect(opts.command_names).to include('run')
      expect($stdout.string).to match(/walk called/)
    }
    And number_of_commands_should_be(2)
  end

  test_that "help is displayed if no command on command line" do
    Given app_has_subcommands('walk','run')
    And {
      @main_called = false
      main do
        @main_called = true
        puts 'main called'
      end
    }
    When run_go_safely
    Then main_should_not_be_called
    And help_shown
    And {
      $stdout.string.should match /You must specify a command/
    }
  end

  test_that "app with subcommands list subcommands in help" do
    Given app_has_subcommands('walk','run')
    When {
      setup_defaults
      opts.post_setup
    }
    Then {
      opts.to_s.should match /Commands:.*walk: moves slowly.*run:  moves quickly/m
    }
    And {
      opts.to_s.should match /Usage:.*command \[command options and args...\]/
    }
  end

  test_that "app without subcommands do not list command prefix in help" do
    Given {
      main do
      end
      on '--switch'
      on '--flag FOO'
      arg 'must_have'
      arg 'optionals', :any
    }
    When {
      setup_defaults
      opts.post_setup
    }
    Then {
      opts.to_s.should_not match /Commands:/m
    }
  end

  test_that "subcommand can get its own help" do
    Given app_has_subcommands('walk','run')
    And {
      version '1.2.3'
      set_argv %w(walk -h)
    }
    When run_go_safely
    Then {
      $stdout.string.should match /Usage: #{::File.basename($0)} \[global options\] walk \[options\] distance/
    }
  end

  someday_test_that "rc_file can specify defaults for each subcommand" do
  end

  test_that "subcommands have access to global options" do
    Given app_has_subcommands('greet')
    And {
      options[:lang] = 'en'
      on '-l', '--lang LANG','Set the language'
      set_argv %w(-l fr greet)
    }
    When run_go_safely
    Then {
      $stdout.string.should match /Bonjour/
      $stdout.string.should_not match /Hello/
      $stdout.string.should_not match /Hola/
      $stdout.string.should_not match /\?\?\?\?/
    }
  end


private

  def commands_should_include(cmd) 
    proc { expect(opts.commands.keys).to include(cmd)}
  end

  def number_of_commands_should_be(num)
    proc { opts.commands.keys.length.should be(num)}
  end    

  def provider_for_command(cmd)
    opts.commands[cmd]
  end

  def app_has_subcommands(*args)
    proc {
      args.each do |cmd|
        command cmd => get_const("TestMulti::Commands::#{cmd.capitalize}")
      end
    }
  end

  def help_shown
    proc {assert $stdout.string.include?(opts.to_s),"Expected #{$stdout.string} to contain #{opts.to_s}"}
  end

  def app_to_use_rc_file
    lambda {
      @switch = nil
      @flag = nil
      @args = nil
      main do |*args|
        @switch = options[:switch]
        @flag = options[:flag]
        @args = args
      end

      defaults_from_config_file '.my_app.rc'

      on('--switch','Some Switch')
      on('--flag FOO','Some Flag')
    }
  end

  def main_that_exits(exit_status)
    proc { main { exit_status } }
  end

  def app_to_use_environment
    lambda {
      @switch = nil
      @flag = nil
      @args = nil
      main do |*args|
        @switch = options[:switch]
        @flag = options[:flag]
        @args = args
      end

      defaults_from_env_var 'APP_OPTS'

      on('--switch','Some Switch')
      on('--flag FOO','Some Flag')
    }
  end

  def main_should_not_be_called
    Proc.new { assert !@main_called,"Main block was called?!" }
  end

  def main_shouldve_been_called
    Proc.new { assert @main_called,"Main block wasn't called?!" }
  end
  
  def run_go_safely
    Proc.new { safe_go! }
  end

  # Calls go!, but traps the exit
  def safe_go!
    go!
  rescue SystemExit
  end

  def run_go!; proc { go! }; end

  def assert_logged_at_error(expected_message)
    @logged.string.should include expected_message
  end

  def assert_exits(exit_code,message='',&block)
    block.call
    fail "Expected an exit of #{exit_code}, but we didn't even exit!"
  rescue SystemExit => ex
    assert_equal exit_code,ex.status,@logged.string
  end

  def set_argv(args)
    ARGV.clear
    args.each { |arg| ARGV << arg }
  end

  def get_const(class_name)
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ class_name
      raise NameError, "#{class_name.inspect} is not a valid constant name!"
    end

    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end
  
end
