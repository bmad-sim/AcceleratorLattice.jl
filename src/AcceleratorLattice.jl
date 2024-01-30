module AcceleratorLattice

  include("core.jl")
  include("quaternion.jl")
  include("AtomicAndPhysicalConstants.jl")
  include("math_base.jl")
  include("utilities.jl")
  include("switch.jl")
  include("struct.jl")
  include("string.jl")
  include("parameters.jl")
  include("accessor.jl")
  include("manipulation.jl")
  include("geometry.jl")
  include("superimpose.jl")
  include("tracking.jl")
  include("show.jl")
  include("init_bookkeeper.jl")
  include("bookkeeper.jl")
  include("lat_construction.jl")
  include("input_output.jl")
  include("query.jl")
  include("find.jl")
  include("external_ele.jl")

  # Note: Switches and element types are exported automatically when constructed

  export QuatRotation, QuatN, Quat64
  export memloc, beamline, @ele, @construct_ele_type, expand, ele_name, show_name, show_ele
  export show_lat, show_branch, show_beamline, get_property, bookkeeper!, set_param!
  export InfiniteLoop, Branch, Lat, BeamLineEle, superimpose!, multipole_type
  export BeamLineItem, BeamLine, Ele, ele_types_set, propagate_ele_geometry, ele_floor_transform
  export split!, construct_ele_type, LatEleLocation, ele_at_s, add_governor!
  export find_ele, find_eles, next_ele, branch, matches_branch, ele_param_groups, create_ele_vars
  export EleParameterGroup, AlignmentGroup, FloorPositionGroup, BMultipole1, BMultipoleGroup
  export EMultipole1, EMultipoleGroup, BendGroup, ApertureGroup, StringGroup, RFGroup
  export TrackingGroup, ChamberWallGroup, LengthGroup, ReferenceGroup, MasterGroup
  export GirderGroup, LCavityGroup, PatchGroup, RFFieldGroup, RFMasterGroup, ControlSlaveGroup, ControlVarGroup
  export info, ctrl, var, create_external_ele, ele_param_info, units, ele_param_group_syms
  export show_group, switch_list_dict, lat_sanity_check, NULL_ELE, NULL_BRANCH, is_null
  export struct_sym_to_user_sym, multipole!, index, integer

end
