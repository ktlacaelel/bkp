#!/usr/bin/env ruby

TEMPLATE = "---
-
  # A short one line easy to understand summary of what the backup is for.
  summary:

  # Some context about the backup (why are we doing this?)
  background: |-
    This is a backup of the database for the website.
    You can find the website at http://www.example.com

    It is important to backup the database because it contains all the information for the website.

  # The local diretory you want to backup
  directory: ./mydata

  # The date of the backup
  date: '%<date>s'

  # Who created the backup. (usually your name)
  owner:

  # The ticket url associated with the backup
  ticket: ''

  # The bucket where the backup will be stored
  # (probably okay to keep as is) 
  bucket: %<bucket>s

  # The path where all the backups are stored in the bucket
  # Think about it this way: bucket/path/[backups live here]
  # (probably okay to keep as is) 
  path: %<path>s
"

CONFIG_FILE = "#{ENV['HOME']}/.bkp/config.yml"

DEFAULT_CONFIG = "---
# The default bucket where all backups will be stored
bucket: ''

# The default path where all backups will be stored
# Think about it this way: bucket/path/[backups live here]
path: ''
"

def to_hyphen(string)
  string = string.chomp
  string.gsub!(/\W+/, ' ')
  string.gsub!(/\s+/, '-')
  string.gsub!(/^[-]+|[-]+$/, '')
  string.downcase
end

def create_backup(backup)
  Dir.mktmpdir do |dir|
    # we keep the original directory when we tar and gzip the directory
    run_command "cd #{backup['directory']} && cd .. && tar -czf #{dir}/#{backup['name']}.tar.gz #{backup['directory'].split('/').last}"
    run_command "aws s3 cp #{dir}/#{backup['name']}.tar.gz s3://#{backup['bucket']}/#{backup['path']}/#{backup['name']}/#{backup['name']}.tar.gz"

    manifest = "#{dir}/manifest.json"

    File.open(manifest, 'w+') do |file|
      file.write(backup.to_json)
    end

    run_command "aws s3 cp #{manifest} s3://#{backup['bucket']}/#{backup['path']}/#{backup['name']}/manifest.json"
  end
end

def load_file(file)
  unless File.exist?(file)
    $stderr.puts "Backup File #{file.inspect} does not exist."
    exit 1
  end

  backups = YAML.load_file(file)

  backups.each_with_index do |backup, index|
    validate_summary(backup['summary'], index)
    validate_background(backup['background'], index)
    validate_directory(backup['directory'], index)
    validate_date(backup['date'], index)
    validate_owner(backup['owner'], index)
    validate_ticket(backup['ticket'], index)
    validate_bucket(backup['bucket'], index)
    validate_path(backup['path'], index)
    date = Time.parse(backup['date'], index)
    date = date.strftime('%Y-%m-%d')
    backup['name'] = date + '-' + to_hyphen(backup['summary'])
  end
end

def backup_list
  config = YAML.load_file(CONFIG_FILE)
  list = File.expand_path("~/.bkp/list.txt")
  run_command "aws s3 ls s3://#{config['bucket']}/#{config['path']}/ > #{list}"
  files = []
  File.read(list).each_line do |line|
    files << line.split(' ').last
  end
  files
end

def download_manifests
  config = YAML.load_file(CONFIG_FILE)
  backups = backup_list
  FileUtils.mkdir_p(File.expand_path('~/.bkp/manifests'))
  FileUtils.rm(Dir.glob(File.expand_path('~/.bkp/manifests/*.json')))
  backups.each do |backup|
    backup = backup.split('/').first
    run_command "aws s3 cp s3://#{config['bucket']}/#{config['path']}/#{backup}/manifest.json ~/.bkp/manifests/#{backup}.json"
  end
  reload_manifests
end

def load_manifests
  Dir.glob(File.expand_path('~/.bkp/manifests/*.json')).map do |file|
    object = JSON.parse(File.read(file))
    Ona.register(:backup) do |backup|
      backup.name = object['name']
      backup.summary = object['summary']
      backup.background = object['background']
      backup.directory = object['directory']
      backup.date = object['date']
      backup.owner = object['owner']
      backup.ticket = object['ticket']
      backup.bucket = object['bucket']
      backup.path = object['path']
    end
  end
end

def unload_manifests
  Ona.class_eval do
    puts @resources[:backup][:entries] = []
  end
end

def reload_manifests
  unload_manifests
  load_manifests
end

def config_check
  return if File.exist?(CONFIG_FILE)

  puts "Config file #{CONFIG_FILE.inspect} does not exist."

  unless Ona.confirm('Okay to create a new config file in ~/.bkp/config.yml?', 'yes')
    $stderr.puts 'Will exit this program now.'
    exit 1
  end

  puts 'What is the name of the bucket where you want to store your backups?'
  print 'S3 Bucket name> '
  bucket = gets.chomp

  puts "What is the 'path' where you want to store your backups?"
  print 'S3 Bucket path> '
  path = gets.chomp

  config = YAML.load(DEFAULT_CONFIG)
  config['bucket'] = bucket
  config['path'] = path
  FileUtils.mkdir_p(File.expand_path('~/.bkp'))
  File.open(CONFIG_FILE, 'w+') do |file|
    file.write(config.to_yaml)
  end
end

# we use gsub because older rubies format method works differently.
def generate_template
  config = YAML.load_file(CONFIG_FILE)
  template = TEMPLATE.dup
  template.gsub!('%<date>s', Time.now.to_s)
  template.gsub!('%<bucket>s', config['bucket'])
  template.gsub!('%<path>s', config['path'])
  puts template
end

def run_command(command)
  puts ''
  puts "# Command: #{command.to_ansi.yellow.to_s}"
  puts "# Executed at: #{Time.now.to_s}"
  puts "# #{('=' * 76).to_ansi.cyan.to_s}"
  system command
  puts ''
end

def pretty_backup_list(id, backup)
  pretty_id     = id.to_s.to_s.rjust(5, ' ').to_ansi.cyan.to_s
  pretty_name   = 'name'.to_ansi.green.to_s
  pretty_date   = backup.date.to_ansi.yellow.to_s
  puts "#{pretty_id} - [#{pretty_date}] #{pretty_name}: #{backup.name}"
end

def pretty_backup_body(id, backup)
  puts ''
  puts 'Summary:'.to_ansi.green.to_s
  puts backup.summary.to_ansi.cyan.to_s
  puts ''
  puts 'Background:'.to_ansi.green.to_s
  puts backup.background.to_ansi.cyan.to_s
  puts ''
  puts 'Date:'.to_ansi.green.to_s
  puts backup.date.to_ansi.cyan.to_s
  puts ''
  puts 'Owner:'.to_ansi.green.to_s
  puts backup.owner.to_ansi.cyan.to_s
  puts ''
  puts 'Ticket:'.to_ansi.green.to_s
  puts backup.ticket.to_ansi.cyan.to_s
  puts ''
  puts 'Bucket:'.to_ansi.green.to_s
  puts backup.bucket.to_ansi.cyan.to_s
  puts ''
  puts 'Path:'.to_ansi.green.to_s
  puts backup.path.to_ansi.cyan.to_s
  puts ''
  puts 'Directory:'.to_ansi.green.to_s
  puts backup.directory.to_ansi.cyan.to_s
  puts ''
  puts 'S3 Path:'.to_ansi.green.to_s
  puts s3_path(backup).to_ansi.cyan.to_s
  puts ''

end

def s3_path(backup)
  's3://' + backup.bucket + '/' + backup.path + '/' + backup.name + '/' + backup.name + '.tar.gz'
end
