require 'optparse'

def expand_dirs_to_files *dirs
  # extensions = ['rb', 'erb', 'builder']
  extensions = ['rb', 'builder']

  dirs.flatten.map { |p|
    if File.directory? p
      Dir[File.join(p, '**', "*.{#{extensions.join(',')}}")]
    else
      p
    end
  }.flatten.sort { |a, b|
    # for law_of_demeter_check
    if a =~ /models\/.*rb/
      -1
    elsif b =~ /models\/.*rb/
      1
    else
      a <=> b
    end
  }
end

# for always_add_db_index_check
def add_duplicate_migration_files files
  migration_files = files.select { |file| file.index("db/migrate") }
  (files << migration_files).flatten
end

def ignore_vendor_directories files
  files.reject { |file| file.index("vendor/") }
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: rails_best_practices [options]"
  
  opts.on("-d", "--debug", "Debug mode") do
    options['debug'] = true
  end
  
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.parse!
end

runner = RailsBestPractices::Core::Runner.new
runner.set_debug if options['debug']
ignore_vendor_directories(add_duplicate_migration_files(expand_dirs_to_files(ARGV))).each { |file| runner.check_file(file) }
runner.errors.each {|error| puts error}
puts "\nFound #{runner.errors.size} errors."

exit runner.errors.size
