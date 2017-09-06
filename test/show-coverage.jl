using Coverage
# defaults to src/; alternatively, supply the folder name as argument
coverage = process_folder()
# Get total coverage for all Julia files
covered_lines, total_lines = get_summary(coverage)
# Or process a single file
@show get_summary(process_file("src/Q.jl"))
@show get_summary(process_file("src/_k.jl"))
