"""
    module AcceleratorLattice

Module for instantiating and manipulating lattices for particle beam machines.
"""
module AcceleratorLattice

  ## using OffsetArrays
  using InteractiveUtils      # Defines subtypes function
  using PyFormattedStrings
  using Accessors
  using LinearAlgebra
  using Rotations

  import Base.Cartesian.lreplace

  include("core.jl")
  include("quaternion.jl")
  include("AtomicAndPhysicalConstants.jl")
  include("math_base.jl")
  include("struct.jl")
  include("utilities.jl")
  include("string.jl")
  include("traversal.jl")
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

  # Note! Element types are exported automatically when constructed

  export QuatRotation, QuatN, Quat64
  export memloc, beamline, @ele, @eles, @construct_ele_type, expand, ele_name, show_name, show_ele
  export show_lat, show_branch, show_beamline, get_property, bookkeeper!, set_param!
  export InfiniteLoop, Branch, Lat, BeamLineEle, superimpose!, multipole_type
  export BeamLineItem, BeamLine, Ele, propagate_ele_geometry, ele_floor_transform
  export split!, construct_ele_type, LatEleLocation, ele_at_s, add_governor!
  export find_ele, find_eles, next_ele, ele_at_index
  export branch, matches_branch, param_groups_list, create_ele_vars
  export EleParameterGroup, AlignmentGroup, FloorPositionGroup, BMultipole1, BMultipoleGroup
  export EMultipole1, EMultipoleGroup, BendGroup, ApertureGroup, StringGroup, RFGroup, SolenoidGroup
  export TrackingGroup, ChamberWallGroup, LengthGroup, ReferenceGroup, MasterGroup, LordSlaveGroup
  export GirderGroup, LCavityGroup, PatchGroup, RFFieldGroup, RFMasterGroup, ControlSlaveGroup, ControlVarGroup
  export TwissGroup, Twiss1, InitSpinGroup, InitParticleGroup
  export info, ctrl, var, create_external_ele, ele_param_info, units, ele_param_group_syms
  export show_group, switch_list_dict, lat_sanity_check, NULL_ELE, NULL_BRANCH, is_null
  export struct_sym_to_user_sym, multipole!, index, integer, quat_angles
  export machine_location, body_location, EleRegion, multipole_param_info
  export BranchType, LordBranch, TrackingBranch, MultipassLordBranch, SuperLordBranch, GovernorBranch

end # module
