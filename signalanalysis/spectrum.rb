#!/usr/bin/ruby

require 'pty'
require 'expect'
require 'colorize'

$verbose = false
$stop = false

$first_comparison = ''
$last_comparison = ''
$compare = false

def start single=false
  cmd = 'inspectrum'
  begin
    PTY.spawn(cmd) do |stdout, stdin, pid|
      begin
        control stdout, pid
        listen stdout
        until $stop
          control stdout, pid
        end
      rescue Errno::EIO
        puts '[!] Errno:EIO error, this may just mean the process has finished giving output'.colorize(:red)
      end
    end
  rescue PTY::ChildExited
    puts '[!] The child process exited!'.colorize(:red)
  end
end

def start_inspection iteration
  cmd = 'inspectrum'
  this_pid = 0
  begin
    PTY.spawn(cmd) do |stdout, stdin, pid|
      this_pid = pid
      begin
        listen stdout
      rescue Errno::EIO
        puts '[!] Errno:EIO error, this may just mean that the process has finished giving output'.colorize(:red)
      end
    end
  rescue PTY::ChildExited
    puts '[!] The child process exited!'.colorize(:red)
  end

  if iteration == 1
    # kill this one off
    Process.kill 'INT', this_pid
    start_inspection 2
  elsif iteration == 2
    # kill & return to normal operation
    Process.kill 'INT', this_pid
    start
  end
end

def listen r
  got_it = false

  loop do
    if !got_it
      line = r.gets
      unless line.nil?
        raw = line.chomp.strip.split(',')
        puts "\n[*] Data as array: #{raw}" if $verbose == true
        if raw.count > 1
          collected_at = Time.now
          puts "\n---------------------------------------------"
          puts "[*] Processed At: #{collected_at}"
          puts "---------------------------------------------\n"

          demod = ''
          # threshold = 1

          arr = raw
          threshold = arr.inject { |sum, el| sum + el }.to_f / arr.size

          raw.to_a.each do |r|
            r.to_f > threshold.to_f ? demod << '1' : demod << '0'
          end

          # threshold safety check start

          threshold_safety_check raw, threshold
          # threshold safety check end

          hex = print_results demod
          compare demod
          got_it = true unless hex == ''
        end
      end
    else
      break
    end
  end
end

def threshold_safety_check raw, threshold
  ranked = raw.to_a.sort
  lowest = ranked.first.to_f
  highest = ranked.last.to_f
  lower_safety = (threshold-lowest)/4
  upper_safety = (highest-threshold)/4

  higher_warnings = 0
  lower_warnings = 0
  fence_warnings = 0

  raw.each do |r|
    if r.to_f > threshold
      higher_warnings += 1 unless (r.to_f-upper_safety > 0)
    elsif r.to_f < threshold
      lower_warnings += 1 unless (lower_safety-r.to_f > 0)
    elsif r.to_f == threshold
      fence_warnings += 1
    end
  end

  puts
  puts
  puts "[-] Safety checking threshold:  #{threshold}".colorize(:blue)
  puts "[!] Measurement for a 1 is in between the threshold and the upper safety limit. Occured: #{higher_warnings} times".colorize(:red) if higher_warnings > 0
  puts "[!] Measurement for a 0 is in between the threshold and the lower safety limit. Occured: #{lower_safety} times".colorize(:red) if lower_warnings > 0
  puts "[!] A measurement is equal to the threshold. Occured: #{fence_warnings}".colorize(:red) if fence_warnings > 0
  puts '[-] No threshold issues identified'.colorize(:blue) if fence_warnings + lower_warnings + higher_warnings == 0
  puts "[!] The issues listed above point to a low confidence level that I was able to guess the correct threshold. You'll want to manually verify these results.".colorize(:red) if fence_warnings + lower_warnings + higher_warnings != 0

end

def print_results demod
  hex = ''
  f_hex = '\x'
  hex << '%02x' % demod.to_i(2)
  f_hex << hex.scan(/.{2}|.+/).join('\x')

  puts
  puts
  puts "[*] Binary: \t\t#{demod}".colorize(:green)
  puts "[*] Hexcode: \t\t#{hex}".colorize(:green)
  puts "[*] Formatted Hexcode: \t#{f_hex}".colorize(:green)
  puts "[*] Ascii:  \t\t#{hex.gsub(/../) { |pair| pair.hex.chr }}".colorize(:green)
  puts
  return hex
end

def compare demod
  if $compare
    if $first_comparison == ''
      $first_comparison = demod
    elsif $last_comparison == ''
      $last_comparison = demod
      b = ''
      l = ''

      if $first_comparison > $last_comparison
        b = $first_comparison
        l = $last_comparison
      else
        l = $first_comparison
        b = $last_comparison
      end

      comparison_string = ''
      b=b.scan(/\w/)
      l=l.scan(/\w/)
      b.each_with_index { |x, i| (x == l[i]) ? comparison_string << "[#{x}]" : comparison_string << '[-]' }
      bs = ''
      ls = ''
      b.each { |bb| bs << "[#{bb}]" }
      l.each { |ll| ls << "[#{ll}]" }

      puts "[** Position Comparison **]\n"
      if $first_comparison.size == bs.size
        puts bs + "\n" + ls + "\n" + comparison_string + "\n\n"
      else
        puts ls + "\n" + bs + "\n" + comparison_string + "\n\n"
      end

      $first_comparison = ''
      $last_comparison = ''
      $compare = false
    end
  end
end

def control stdout, pid
  listen stdout if $compare
  print "[Enter command, or type 'help'] >  ".colorize(:red)
  input = gets.chomp

  case input
  when 'help'
    help
  when 'stop'
    puts 'Stopping Inspectrum'
    close_inspectrum pid, false
  when 'exit'
    puts 'Happy Reversing!'
    close_inspectrum pid, true
  when 'start'
    puts 'Spawning Inspectrum'
    start
  when 'c'
    listen stdout
  when 'inspect'
    single_file_inspect stdout
  when 'dual'
    dual_file_inspect pid
  when 'verbose'
    toggle_verbose
  end

end

def close_inspectrum pid, exit_script=false
  Process.kill 'INT', pid
  exit if exit_script
end

def single_file_inspect stdout
  $compare = true
  listen stdout
end

def dual_file_inspect pid
  puts 'Inspectrum will re-open twice to allow you to extract bits from two separate files'
  Process.kill 'INT', pid
  $compare = true
  start_inspection 1
end

def toggle_verbose
  $verbose ? (puts 'Verbose mode off.') : (puts 'Verbose mode on')
  $verbose ? ($verbose = false) : ($verbose = true)
end

def help
  # puts "start, continue (c), compare_next_two (inspect)"
  commands = {
      :help => 'Prints this message',
      # "start" => "Spanws Inspectrum & starts listening for a single ",
      :c => 'Continue processing signals from Inspectrum',
      :inspect => 'Compare the next two signals from currently opened file',
      :dual => 'Compare next signal from this file with a signal from another file (re-spawns Inspectrum in between)',
      :stop => 'Closes Inspectrum',
      :start => 'Opens Inspectrum',
      :verbose => 'Include the array of raw data from Inspectrum',
      :exit => 'Quit dspectrum'
  }
  puts 'dspectrum - by nullwolf'.colorize(:red)
  puts 'USAGE: '.colorize(:green)
  commands.each do |k, v|
    print "\t#{k}: ".colorize(:green)
    print "#{v}\n"
  end

end

help
start