#!/usr/bin/ruby

require("optparse")

mpi_init_thread_argv_is_three_star = true
statements_before_call = ""
statements_after_call  = ""
statements_for_prologue = ""
file_for_prologue = nil
exclude_funcs = []

opt = OptionParser.new
opt.on("-v") {|x| mpi_init_thread_argv_is_three_star = true}
opt.on("-V") {|x| mpi_init_thread_argv_is_three_star = false}
opt.on("-b STATEMENTS_BEFORE_CALL")  {|x| statements_before_call  = x}
opt.on("-a STATEMENTS_AFTER_CALL")   {|x| statements_after_call   = x}
opt.on("-p STATEMENTS_FOR_PROLOGUE") {|x| statements_for_prologue = x}
opt.on("-P FILE_FOR_PROLOGUE")       {|x| file_for_prologue       = x}
opt.on("-e EXCLUDE_FUNC1,EXCLUDE_FUNC2,...") {|x| exclude_funcs = x.split(",")}
opt.parse!(ARGV)

if ! statements_before_call.empty? && ! statements_before_call.end_with?("\n")
  statements_before_call << "\n"
end
if ! statements_after_call.empty? && ! statements_after_call.end_with?("\n")
  statements_after_call << "\n"
end
statements_before_call.gsub!(/\n/, "\n    ")
statements_after_call.gsub!(/\n/, "\n    ")

puts <<-END
#include <mpi.h>

END

if ! statements_for_prologue.empty?
  puts(statements_for_prologue)
  puts()
end

if file_for_prologue
  File.open(file_for_prologue) do |file|
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
