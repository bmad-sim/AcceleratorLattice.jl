# Create a list of element groups for an element type for insertion into the element types chapter.

section_dict = Dict(
 AlignmentGroup      => "s:align.g",         
 ApertureGroup       => "s:aperture.g",      
 BMultipoleGroup     => "s:bmultipole.g",    
 BeamBeamGroup       => "s:beam.beam.g",     
 BendGroup           => "s:bend.g",          
 EMultipoleGroup     => "s:emultipole.g",    
 FloorPositionGroup  => "s:floor.pos.g",     
 GirderGroup         => "s:girder.g",        
 InitParticleGroup   => "s:init.particle.g", 
 LCavityGroup        => "s:lcavity.g",       
 LengthGroup         => "s:length.g",        
LordSlaveGroup       => "s:lord.slave.g", 
MasterGroup          => "s:master.g",     
PatchGroup           => "s:patch.g",      
RFCommonGroup        => "s:rfcommon.g",    
RFCavityGroup       => "s:rfcavity.g",         
RFAutoGroup         => "s:rfauto.g",   
ReferenceGroup      => "s:reference.g",  
SolenoidGroup       => "s:solenoid.g",   
StringGroup         => "s:string.g",     
TrackingGroup       => "s:tracking.g",   
TwissGroup          => "s:twiss.g", 
)     

Base.isless(x::Ele, y::Ele) = isless(string(x), string(y))

for etype in subtypes(Ele)
  n = 0
  for group in sort(PARAM_GROUPS_LIST[etype])
    n = max(n, length("$(strip_AL(group))"))
  end


  lst = "\\begin{example}\n"
  for group in sort(PARAM_GROUPS_LIST[etype])
    name = "$(strip_AL(group))"
    lst *= "  $(rpad(name, n)) -> $(ELE_PARAM_GROUP_INFO[group].description) \\sref{$(section_dict[group])} \n"
  end
  lst *= "\\end{example}"

  println("\n\n" * string(etype) * "\n")
  print(lst)
end


function infoz(ele_type::Type{T}) where T <: Ele
    lst = ""
    for group in sort(PARAM_GROUPS_LIST[ele_type])
      name = "`$(strip_AL(group))`"
      lst *= "•  $(rpad(name, 20)) -> $(ELE_PARAM_GROUP_INFO[group].description)\\\n"
    end
    return lst
end

