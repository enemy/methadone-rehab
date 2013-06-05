require 'base_test'
require 'methadone'
require 'stringio'
require 'fileutils'

class TestMulti < BaseTest
  include Methadone::Main

  def setup
    @original_argv = ARGV.clone
    ARGV.clear
    @old_stdout = $stdout
    $stdout = StringIO.new
    @logged = StringIO.new
    @custom_logger = Logger.new(@logged)

    @original_home = ENV['HOME']
    fake_home = '/tmp/fake-home'
    FileUtils.rm_rf(fake_home)
    FileUtils.mkdir(fake_home)
    ENV['HOME'] = fake_home
  end

  # Override the built-in logger so we can capture it
  def logger
    @custom_logger
  end

  def teardown
    @commands = nil
    set_argv @original_argv
    ENV.delete('DEBUG')
    ENV.delete('APP_OPTS')
    $stdout = @old_stdout
    ENV['HOME'] = @original_home
  end

  test_that "commands can be specified" do
    Given {
      module Commands
        class Walk
          include Methadone::Main

          main do
          end
        end
      end
      
    }
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
      module Commands
        class Walk
          include Methadone::Main
          main do
          end
        end
      end

      main do
      end

      command "walk" => Commands::Walk
      set_argv(['walk'])
    }
    When run_go_safely
    Then {
      expect(@selected_command).to eq('walk')
    }
  end

  test_that "command in the arguments causes the right command to be called" do
    Given {
      module Commands
        class Walk
          include Methadone::Main
          main do
            puts "walk called"
          end
        end
        class Run
          include Methadone::Main
          main do
            puts "run called"
          end
        end
      end

      main do
      end

      command "walk" => Commands::Walk
      command "run" => Commands::Run

      set_argv(['walk'])
    }
    When run_go_safely
    Then {
      expect($stdout.string).to match(/walk called/)
    }
  end


private

  def commands_should_include(cmd) 
    proc { expect(commands.keys).to include(cmd)}
  end

  def number_of_commands_should_be(num)
    proc { commands.keys.length.should be(num)}
  end    

  def provider_for_command(cmd)
    commands[cmd]
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

  def main_shouldve_been_called
    Proc.new { assert @called,"Main block wasn't called?!" }
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
end
