#!/usr/bin/ruby

require("optparse")

mpi_init_thread_argv_is_three_star = true
statements_before_call = ""
statements_after_call  = ""
exclude_funcs = []
prologue_file = nil

opt = OptionParser.new
opt.on("-v") {|x| mpi_init_thread_argv_is_three_star = true}
opt.on("-V") {|x| mpi_init_thread_argv_is_three_star = false}
opt.on("-b STATEMENTS_BEFORE_CALL") {|x| statements_before_call = x}
opt.on("-a STATEMENTS_AFTER_CALL")  {|x| statements_after_call  = x}
opt.on("-e EXCLUDE_FUNC1,EXCLUDE_FUNC2,...") {|x| exclude_funcs = x.split(",")}
opt.on("-p PROLOGUE_FILE") {|x| prologue_file = x}
opt.parse!(ARGV)

if ! statements_before_call.empty?
  statements_before_call += "\n"
end
if ! statements_after_call.empty?
  statements_after_call += "\n"
end
statements_before_call.gsub!(/\n/, "\n    ")
statements_after_call.gsub!(/\n/, "\n    ")

puts <<-END
#include <mpi.h>

END

if prologue_file
  File.open(prologue_file) do |file|
    print(file.read)
  end
end

ARGF.each do |line|

  if line =~ /^(\w+) (\w+)\((.+)\);$/

    ret_type = $1
    func_name = $2
    formal_params = $3

    if mpi_init_thread_argv_is_three_star && func_name == "MPI_Init_thread"
      begin
        formal_params["char *(( *argv)[])"] = "char ***argv"
      rescue
      end
    end

    actual_args =
      formal_params.gsub(/\w+ /, "").gsub(/\[[^\]]*\]/, "").gsub(/\*/, "").
        gsub(/[\(\)] */, "").sub(/^void$/, "")

    if exclude_funcs.include?(func_name)
      puts <<-END.sub(/^\t/, "")
	#if 0
	END
    end

    func_def = <<-END.gsub(/^\t/, "")
	#{ret_type} #{func_name}(#{formal_params})
	{
	    #{ret_type} ret;
	    #{statements_before_call}ret = P#{func_name}(#{actual_args});
	    #{statements_after_call}return ret;
	}
	END
    puts(func_def)

    if exclude_funcs.include?(func_name)
      puts <<-END.sub(/^\t/, "")
	#endif
	END
    end

  else
    puts(line)
  end
end
