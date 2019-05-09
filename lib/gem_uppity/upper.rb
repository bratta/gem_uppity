# frozen_string_literal: true

# This code works but it needs some love to make it robust.
# It handles 90% of use cases but needs tests. There's also
# probably better ways to do some of the things, such as
# getting the latest version of a particular gem. Help me
# help you and submit a PR if you see any way to improve it!

require 'rubygems'
require 'pathname'
require 'bundler'

# This is where the magic happens
module GemUppity
  # Upper Class; performs the upgrade
  class Upper
    attr_accessor :gemfile, :lockfile

    def initialize(gemfile = nil)
      @gemfile = gemfile || File.join(Dir.pwd, 'Gemfile')
      @lockfile = "#{@gemfile}.lock"

      raise IOError, 'Cannot find a valid Gemfile in the specified name or current directory' unless File.file?(@gemfile)
      raise IOError, 'Cannot find a valid Gemfile.lock in the specified name or current directory' unless File.file?(@lockfile)
    end

    def upgrade
      current_directory = Dir.pwd
      pathname = Pathname.new(@gemfile)

      Dir.chdir(pathname.dirname)
      definition = Bundler::Definition.build(@gemfile, @lockfile, false)
      print_header_for_definition(definition)
      dependencies = grouped_dependencies(definition.dependencies)
      print_grouped_dependencies(dependencies)
      Dir.chdir(current_directory)
    end

    private

    def print_header_for_definition(definition)
      puts warning_comment
      puts "\n"
      puts "source 'https://rubygems.org'\n\n"
      ruby_version = definition.ruby_version&.versions&.first
      puts "ruby '#{ruby_version}'\n\n" if ruby_version
    end

    def grouped_dependencies(dependencies)
      {}.tap do |group|
        dependencies.each do |dependency|
          group[dependency.groups] ? group[dependency.groups] << dependency : group[dependency.groups] = [dependency]
        end
      end
    end

    def print_grouped_dependencies(dependencies, spacing = '')
      dependencies.keys.each do |group|
        unless group == [:default]
          puts "\ngroup :#{group.join(', :')} do"
          spacing = '  '
        end
        dependencies[group].each do |dependency|
          print_dependency_info(dependency, spacing)
        end
        puts 'end' unless group == [:default]
      end
    end

    def print_dependency_info(dependency, spacing = '')
      if dependency.source.is_a?(Bundler::Source::Git)
        print_github_dependency(dependency, spacing)
      else
        print_basic_dependency(dependency, spacing)
      end
    end

    def print_github_dependency(dependency, spacing = '')
      puts "#{spacing}gem '#{dependency.name}',"
      puts "#{spacing}  git: '#{dependency.source.uri}',"
      puts "#{spacing}  branch: '#{dependency.source.branch}'"
    end

    def print_basic_dependency(dependency, spacing = '')
      original_version_string = get_original_version_string(dependency)
      version_string = original_version_string
      version = latest_version_of(dependency.name)
      version_string = "'~> #{version}'" if version
      require_string = get_autorequire_string(dependency.autorequire)
      puts "#{spacing}gem '#{dependency.name}', #{version_string}#{require_string}  # #{original_version_string}"
    end

    def latest_version_of(gem_name)
      output = `gem search --no-verbose -r ^#{gem_name}$`.chomp
      matches = output.match(/^#{gem_name} \(([.\d]+).*\)$/)
      matches && matches.length == 2 ? matches[1] : nil
    end

    def get_original_version_string(dependency)
      versions = dependency.requirement.to_s.split(/,/)
      versions.map { |version| "'#{version.to_s.strip}'" }.join(', ')
    end

    def get_autorequire_string(requires)
      autorequire_string = ''
      if requires
        autorequire_string = requires.count.positive? ? ", require: '#{requires.join(', ')}'" : ', require: false'
      end
      autorequire_string
    end

    def warning_comment
      <<~WARNING_COMMENT
        # !=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=
        # Gemfile generated by Gem Uppity
        # -------------------------------
        # Use at your own risk! This will attempt to use the latest
        # version of gems in your Gemfile regardless of their current
        # versions, formatting a new Gemfile with all versions specified
        # where possible. Currently, gems specified with git repositories
        # are left as-is.
        # !=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=!=
      WARNING_COMMENT
    end
  end
end