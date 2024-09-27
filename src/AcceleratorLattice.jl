"""
    module AcceleratorLattice

Module for instantiating and manipulating lattices for particle beam machines.
Part of the SciBmad ecosystem of packages for simulation of high energy 
"""
module AcceleratorLattice

  import Base.Cartesian.lreplace

  using InteractiveUtils      # Defines subtypes function
  using PyFormattedStrings
  using Accessors
  using LinearAlgebra
  using ReferenceFrameRotations
  using EnumX
  using Random
  using OrderedCollections
  using AtomicAndPhysicalConstants

  # AtomicAndPhysicalConstants

  setunits()

  function __init__()
    setunits()
  end

  for name in names(AtomicAndPhysicalConstants)
    eval(Meta.parse("export $name"))
  end

  mass(species::Species) = massof(species)
  charge(species::Species) = chargeof(species)

  #

  include("core.jl")
  include("enum.jl")
  include("quaternion.jl")
##  include("AtomicAndPhysicalConstants.jl")
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

  export memloc, beamline, @ele, @eles, @construct_ele_type, enumit, enum_add
  export expand, ele_name, show_name, show_ele, E_tot, pc
  export show_lat, show_branch, show_beamline, get_property, bookkeeper!, set_param!
  export InfiniteLoop, Branch, Lat, BeamLineEle, superimpose!, multipole_type
  export BeamLineItem, BeamLine, Ele, propagate_ele_geometry, ele_floor_transform
  export split!, construct_ele_type, ele_at_s, add_governor!
  export eles, next_ele, ele_at_offset, ele_param_value_str, strip_AL, ele_param_group_symbols
  export branch, matches_branch, PARAM_GROUPS_LIST, create_ele_vars, eval_str
  export EleParameterGroup, AlignmentGroup, FloorPositionGroup, BMultipole1, BMultipoleGroup, BeamBeamGroup
  export EMultipole1, EMultipoleGroup, BendGroup, ApertureGroup, StringGroup, RFCommonGroup, SolenoidGroup
  export TrackingGroup, ChamberWallGroup, LengthGroup, ReferenceGroup, MasterGroup, LordSlaveGroup
  export GirderGroup, LCavityGroup, PatchGroup, RFCavityGroup, RFMasterGroup
  export TwissGroup, Twiss1, InitSpinGroup, InitParticleGroup
  export info, ctrl, var, create_external_ele, ele_param_info, units, ele_param_group_syms
  export show_group, switch_list_dict, lat_sanity_check, NULL_ELE, NULL_BRANCH, is_null
  export struct_sym_to_user_sym, multipole!, index, integer, quat_angles
  export machine_location, body_location, EleRegion, multipole_param_info
  export BranchType, LordBranch, TrackingBranch, MultipassLordBranch, SuperLordBranch, GovernorBranch
  export str_split, str_match, str_unquote, str_quote, str_to_int, OPEN, CLOSED

end # module
