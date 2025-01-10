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
using Reexport
@reexport using AcceleratorSimUtils
@reexport using AtomicAndPhysicalConstants

# AtomicAndPhysicalConstants

@APCdef;

function charge(species::Species)
  if species == Species(); error("Species not set!"); end
  return chargeof(species)
end

function mass(species::Species)
  if species == Species(); error("Species not set!"); end
  return massof(species)
end

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
include("output_lat.jl")
include("query.jl")
include("find.jl")

# Note! Element types, enums, and Holy traits are exported automatically when constructed.

export memloc, beamline, @ele, @eles, @construct_ele_type, enum, enum_add
export ele_name, show_name, show_ele, msng, E_kinetic, pc, β, β1, γ
export show_lat, show_branch, show_beamline, bookkeeper!, set_param!
export Branch, Lattice, BeamLineEle, superimpose!, multipole_type
export BeamLineItem, BeamLine, Ele, propagate_ele_geometry, coord_transform
export split!, construct_ele_type, ele_at_s, toggle_integrated!
export eles_search, eles_substitute_lords!, eles_sort!
export next_ele, ele_at_offset, ele_param_value_str, strip_AL, ele_param_group_symbols
export branch, matches_branch, create_ele_vars, eval_str, Vertex1, LatticeGlobal
export EleParams, PositionParams, BodyShiftParams, FloorParams, BMultipole, BMultipoleParams, BeamBeamParams
export EMultipole, EMultipoleParams, BendParams, ApertureParams, DescriptionParams, RFParams, SolenoidParams
export TrackingParams, LengthParams, ReferenceParams, DownstreamReferenceParams, ForkParams
export MasterParams, LordSlaveStatusParams, ACKickerParams
export GirderParams, PatchParams, RFAutoParams, OutputParams, full_parameter_name
export BeginningParams, Twiss1, Wall2D, Vertex1, InitSpinParams, InitParticleParams, show_changed
export info, ele_param_info, param_units, ele_param_group_syms
export show_group, switch_list_dict, lat_sanity_check, NULL_ELE, NULL_BRANCH, is_null
export ele_param_struct_field_to_user_sym, multipole!, index, integer, rot_angles, Quaternion
export machine_location, body_location, EleRegion, holy_traits, output_parameter
export BranchType, LordBranch, TrackingBranch, MultipassBranch, SuperBranch, transform
export str_split, str_match, str_unquote, str_quote, str_to_int, associated_names
export DO_NOT_SHOW_PARAMS_LIST, ELE_PARAM_GROUP_INFO, ELE_TYPE_INFO, PARAM_GROUPS_LIST, OPEN, CLOSED
export rotX, rotY, rotZ, rot, rot!, bend_quaternion, lat_ele_dict

# From LinearAlgebra
export norm

end # module
