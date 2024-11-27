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
  using SimUtils
  using AtomicAndPhysicalConstants

  # AtomicAndPhysicalConstants

  @APCdef;

  for name in names(AtomicAndPhysicalConstants)
    eval(Meta.parse("export $name"))
  end

  function species(str::String)
    if str == "NotSet"; return Species("muon"); end
    return Species(str)
  end

  C_light = C_LIGHT
  charge(species::Species) = chargeof(species)


  #

  include("core.jl")
  include("enum.jl")
  include("quaternion.jl")
  include("struct.jl")
  include("utilities.jl")
  include("string.jl")
  include("traversal.jl")
  include("parameters.jl")
  include("accessor.jl")
  include("manipulation.jl")
  include("geometry.jl")
  include("superimpose.jl")
  include("show.jl")
  include("bookkeeper.jl")
  include("lat_construction.jl")
  include("input_output.jl")
  include("query.jl")
  include("find.jl")
  include("external_ele.jl")

  # Note! Element types, enums, and Holy traits are exported automatically when constructed.

  export memloc, beamline, @ele, @eles, @construct_ele_type, enum, enum_add
  export ele_name, show_name, show_ele, E_tot, E_kinetic, pc, β, β1, γ
  export show_lat, show_branch, show_beamline, bookkeeper!, set_param!
  export Branch, Lattice, BeamLineEle, superimpose!, multipole_type
  export BeamLineItem, BeamLine, Ele, propagate_ele_geometry, ele_floor_transform
  export split!, construct_ele_type, ele_at_s, add_governor!, toggle_integrated!
  export eles, next_ele, ele_at_offset, ele_param_value_str, strip_AL, ele_param_group_symbols
  export branch, matches_branch, create_ele_vars, eval_str, Vertex1, LatticeGlobal
  export EleParameterGroup, AlignmentGroup, FloorPositionGroup, BMultipole1, BMultipoleGroup, BeamBeamGroup
  export EMultipole1, EMultipoleGroup, BendGroup, ApertureGroup, DescriptionGroup, RFCommonGroup, SolenoidGroup
  export TrackingGroup, LengthGroup, ReferenceGroup, DownstreamReferenceGroup
  export MasterGroup, LordSlaveStatusGroup
  export GirderGroup, LCavityGroup, PatchGroup, RFCavityGroup, RFAutoGroup
  export TwissGroup, Twiss1, Wall2D, Vertex1, InitSpinGroup, InitParticleGroup, show_changed
  export info, ctrl, var, create_external_ele, ele_param_info, units, ele_param_group_syms
  export show_group, switch_list_dict, lat_sanity_check, NULL_ELE, NULL_BRANCH, is_null
  export ele_param_struct_field_to_user_sym, multipole!, index, integer, quat_angles, Quaternion
  export machine_location, body_location, EleRegion, holy_traits
  export BranchType, LordBranch, TrackingBranch, MultipassLordBranch, SuperLordBranch, GovernorBranch
  export str_split, str_match, str_unquote, str_quote, str_to_int, OPEN, CLOSED
  export ELE_PARAM_GROUP_INFO, ELE_TYPE_INFO, PARAM_GROUPS_LIST

end # module
