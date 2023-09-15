#!/usr/bin/env ruby

def validate_summary(summary, index)
  if summary.nil? || summary.empty?
    $stderr.puts "Backup(#{index}) summary is empty: #{summary.inspect}"
    exit 1
  end

  if summary.size > 80
    $stderr.puts "Backup(#{index}) summary is too long: #{summary.size} characters"
    exit 1
  end
end

def validate_background(background, index)
  if background.nil? || background.empty?
    $stderr.puts "Backup(#{index}) background is empty: #{background.inspect}"
    exit 1
  end

  if background.size < 80
    $stderr.puts "Backup(#{index}) background is too short: #{background.size} characters"
    exit 1
  end
end

def validate_directory(directory, index)
  if directory.nil? || directory.empty?
    $stderr.puts "Backup(#{index}) directory is empty: #{directory.inspect}"
    exit 1
  end

  unless File.directory?(directory)
    $stderr.puts "Backup(#{index}) directory does not exist: #{directory.inspect}"
    exit 1
  end
end

def validate_date(date, index)
  if date.nil? || date.empty?
    $stderr.puts "Backup(#{index}) date is empty: #{date.inspect}"
    exit 1
  end

  begin
    Time.parse(date)
  rescue ArgumentError
    $stderr.puts "Backup(#{index}) date is not a valid date: #{date.inspect}"
    exit 1
  end
end

def validate_owner(owner, index)
  if owner.nil? || owner.empty?
    $stderr.puts "Backup(#{index}) owner is empty: #{owner.inspect}"
    exit 1
  end
end

def validate_ticket(ticket, index)
  if ticket.nil? || ticket.empty?
    $stderr.puts "Backup(#{index}) ticket is empty: #{ticket.inspect}"
    exit 1
  end
end

def validate_bucket(bucket, index)
  if bucket.nil? || bucket.empty?
    $stderr.puts "Backup(#{index}) bucket is empty: #{bucket.inspect}"
    exit 1
  end
end

def validate_path(path, index)
  if path.nil? || path.empty?
    $stderr.puts "Backup(#{index}) path is empty: #{path.inspect}"
    exit 1
  end
end

