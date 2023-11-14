#-------------------------------------------------------------------------------------
# superimpose!

"""


""" superimpose!





function superimpose!(lat::Lat, super_ele::Ele; offset::Float64 = 0, ref_ele::Ele = NullEle, wrap::BoolSwitch = NotSet,
                      ref_origin::EleRefLocationSwitch = Center, ele_origin::EleRefLocationSwitch = Center)
  if typeof(ref_ele) == Ele; ref_ele = [ref]; end

  for ref in ref_ele
    superimpose1!(lat, super_ele, offset, ref, wrap, offset, ref_origin, ele_origin)
  end
end


#-------------------------------------------------------------------------------------
# superimpose1!


"Used by superimpose! superimposing on on individual ref element."

function superimpose1!(lat::Lat, super_ele::Ele; offset::Float64 = 0, ref_ele::Ele = NULL_ELE, wrap::BoolSwitch = NotSet,
                      ref_origin::EleRefLocationSwitch = Center, ele_origin::EleRefLocationSwitch = Center)


end


