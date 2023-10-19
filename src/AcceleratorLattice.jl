module AcceleratorLattice

  include("AtomicAndPhysicalConstants.jl")
  include("core.jl")
  include("math_base.jl")
  include("utilities.jl")
  include("switch.jl")
  include("struct.jl")
  include("string.jl")
  include("parameters.jl")
  include("manipulation.jl")
  include("geometry.jl")
  include("tracking.jl")
  include("show.jl")
  include("bookkeeper.jl")
  include("lat_construction.jl")
  include("find.jl")
  include("functions.jl")

  export memloc, beamline, @ele, @construct_ele_type, expand, ele_name, show_name, show_ele
  export show_lat, show_branch, show_beamline
  export InfiniteLoop, Branch, Lat, BeamLineEle
  export BeamLineItem, BeamLine, Ele, ele_types_set
  export branch_split!, branch_insert_ele!, branch_bookkeeper!, lat_bookkeeper!, construct_ele_type
  export ele_finder, ele_param_groups, create_ele_vars
  export EleParameterGroup, AlignmentGroup, FloorPositionGroup, BMultipole1, BMultipoleGroup
  export EMultipole1, EMultipoleGroup, BendGroup, ApertureGroup, StringGroup, RFGroup
  export TrackingGroup, ChamberWallGroup, info

end
