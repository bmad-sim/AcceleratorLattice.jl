#+
# Define function that takes an element type and prints in LaTeX format a list of associated
# element groups.
#-


using AcceleratorLattice

function param_groups_for_given_ele_type(ele_type::Type{T}) where T <: Ele
  lst = ""
  for group in sort(PARAM_GROUPS_LIST[ele_type])
    name = "`$(strip_AL(group))`"
    lst *= "•  $(rpad(name, 20)) -> $(ELE_PARAM_GROUP_INFO[group].description)\\\n"
  end
  return lst
end

