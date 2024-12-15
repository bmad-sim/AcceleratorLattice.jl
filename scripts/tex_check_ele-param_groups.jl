#+
# Script to compare element parameter groups discussed in ele-param-group.tex file with 
# how the groups are defined in the AcceleratorLattices.jl code to detect errors in the .tex file.
#
# Run this script in the root AcceleratorLattice directory
#
# Note: In ele-param-group.tex, some example blocks are marked using the syntax:
#
# \begin{example} %
#   ...
# \end{example}
#
# The comment character in the first line of the block will result in this script ignoring the block
# when this script makes a list from the file of what fields a parameter group has.
#
# Note: Due to the complexity of BMultipoleGroup and EMultipoleGroup, these groups are ignored
# by this script.
#-

using AcceleratorLattice

fname = "manual/ele-param-groups.tex"
epgfile = open(fname, "r")

# Parse parameter group table at beginning of file.

group_list = Dict()
line = ""

while true
  global line = readline(epgfile)
  if occursin("\\end{table}", line); break; end

  if !occursin("& \\sref", line); continue; end
  local svec = split(line, "&")
  ref = strip(split(svec[2], "}")[1])[7:end]
  group_list[strip(svec[1])] = ref
  if strip(svec[3]) == ""; break; end
  ref = strip(split(svec[4], "}")[1])[7:end]
  group_list[strip(svec[3])] = ref
end

# Parse sections

while true
  global line
  if !startswith(line, "\\section{"); line = strip(readline(epgfile)); end
  if eof(epgfile); break; end
  if !startswith(line, "\\section{"); continue; end
  if !endswith(line, "Group}"); continue; end

  group = split(line[10:end], '}')[1]
  if group ∉ keys(group_list); error("`$(group)` not in table of groups at top of $fname file."); end

  line = readline(epgfile)
  if !startswith(line, "\\label{"); error("Expected `\\label{`"); end
  label = split(line[8:end], '}')[1]
  if group_list[group] != label; println("$group label different between table ($(group_list[group])) and section $label"); end
  pop!(group_list, group)

  # Find field definitions. First find beginning of list.
  if group == "BMultipoleGroup"|| group == "EMultipoleGroup"; continue; end

  fields_in_file = []
  in_example = false

  while true
    global line = strip(readline(epgfile))
    if line == "\\begin{example}"; in_example = true; end
    if line == "\\end{example}"; in_example = false; end
    if startswith(line, "\\section{") || eof(epgfile); break; end

    if in_example && occursin("::", line)
      push!(fields_in_file, split(line, "::")[1])
    end
  end

  fields_in_struct = string.(fieldnames(eval_str(group)))
  for f in fields_in_struct
    if f ∉ fields_in_file; println("Field `$f` in group $group but not in list in file $fname"); end
  end

  for f in fields_in_file
    if f ∉ fields_in_struct; println("Field `$f` in file $fname for group $group not actually in the struct."); end
  end

  println("---------------- Finished: $group ------------------") 
end

if length(group_list) != 0
  println("Groups in table of groups at top of $fname that do not have a corresponding section:")
  println(group_list)
end