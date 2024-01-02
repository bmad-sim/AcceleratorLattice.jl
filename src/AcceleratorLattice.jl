module AcceleratorLattice

  include("AtomicAndPhysicalConstants.jl")
  include("core.jl")
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
  include("query.jl")
  include("find.jl")
  include("functions.jl")

  # Note: Switches are exported automatically when constructed

  export memloc, beamline, @ele, @construct_ele_type, expand, ele_name, show_name, show_ele
  export show_lat, show_branch, show_beamline, get_property, bookkeeper!
  export InfiniteLoop, Branch, Lat, BeamLineEle, superimpose!
  export BeamLineItem, BeamLine, Ele, ele_types_set, propagate_ele_geometry, ele_floor_transform
  export branch_split!, branch_insert_ele!, branch_bookkeeper!, lat_bookkeeper!, construct_ele_type
  export ele_find, eles_find, branch_find, ele_param_groups, create_ele_vars
  export EleParameterGroup, AlignmentGroup, FloorPositionGroup, BMultipole1, BMultipoleGroup
  export EMultipole1, EMultipoleGroup, BendGroup, ApertureGroup, StringGroup, RFGroup
  export TrackingGroup, ChamberWallGroup, LengthGroup, ReferenceGroup, MasterGroup
  export GirderGroup, LCavityGroup, PatchGroup, RFFieldGroup, RFMasterGroup, ControlSlaveGroup, ControlVarGroup
  export info, ctrl, var, create_external_ele, ele_param_info, units, ele_param_group_syms
  export ele, show_group, switch_list_dict

end
