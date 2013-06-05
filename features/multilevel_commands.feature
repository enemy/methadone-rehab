Feature: Support multi-level commands
  As a developer who wants to make a multi-level command line app
  I should be able to create a Methadone class that delegates subcommands to other Methadone classes
  and each should support their own options, args and potentially other subcommands.

  Background:
    Given the directory "tmp/multigem" does not exist
    And the directory "tml/multi-gem" does not exist

  Scenario: Bootstrap a multi-level app from scratch
    When I successfully run `methadone --commands walk,run,crawl,dance tmp/multigem`
    Then the following directories should exist:
      |tmp/multigem                           |
      |tmp/multigem/bin                       |
      |tmp/multigem/lib                       |
      |tmp/multigem/lib/multigem              |
      |tmp/multigem/lib/multigem/commands     |
      |tmp/multigem/test                      |
      |tmp/multigem/features                  |
      |tmp/multigem/features/support          |
      |tmp/multigem/features/step_definitions |
    Then the following directories should not exist:
      |tmp/multigem/spec |
    And the following files should exist:
      |tmp/multigem/multigem.gemspec                            |
      |tmp/multigem/Rakefile                                    |
      |tmp/multigem/.gitignore                                  |
      |tmp/multigem/Gemfile                                     |
      |tmp/multigem/bin/multigem                                |
      |tmp/multigem/lib/multigem/version.rb                     |
      |tmp/multigem/lib/multigem/commands/walk.rb               |
      |tmp/multigem/lib/multigem/commands/run.rb                |
      |tmp/multigem/lib/multigem/commands/crawl.rb              |
      |tmp/multigem/lib/multigem/commands/dance.rb              |
      |tmp/multigem/features/multigem.feature                   |
      |tmp/multigem/features/support/env.rb                     |
      |tmp/multigem/features/step_definitions/multigem_steps.rb |
      |tmp/multigem/test/tc_something.rb                        |
    And the file "tmp/multigem/.gitignore" should match /results.html/
    And the file "tmp/multigem/.gitignore" should match /html/
    And the file "tmp/multigem/.gitignore" should match /pkg/
    And the file "tmp/multigem/.gitignore" should match /.DS_Store/
    And the file "tmp/multigem/multigem.gemspec" should match /add_development_dependency\('aruba'/
    And the file "tmp/multigem/multigem.gemspec" should match /add_development_dependency\('rdoc'/
    And the file "tmp/multigem/multigem.gemspec" should match /add_development_dependency\('rake', '~> 0.9.2'/
    And the file "tmp/multigem/multigem.gemspec" should match /add_dependency\('methadone'/
    And the file "tmp/multigem/multigem.gemspec" should use the same block variable throughout
    And the file "tmp/multigem/bin/multigem" should match /command "walk" => Multigem::Commands::Walk/
    And the file "tmp/multigem/bin/multigem" should match /command "run" => Multigem::Commands::Run/
    And the file "tmp/multigem/bin/multigem" should match /command "crawl" => Multigem::Commands::Crawl/
    And the file "tmp/multigem/bin/multigem" should match /command "dance" => Multigem::Commands::Dance/
    Given I cd to "tmp/multigem"
    And my app's name is "multigem"
    When I successfully run `bin/multigem --help` with "lib" in the library path
    Then the banner should be present
    And the banner should document that this app takes options
    And the following options should be documented:
      |--version|
      |--help|
      |--log-level|


  @wip
  Scenario: Special characters in subcommands and gem name
    Given PENDING: code not yet in place
    When I run `methadone --commands walk,run,crawl_to_bed,tap-dance tmp/multi-gem`
    Then there should be no errors.

