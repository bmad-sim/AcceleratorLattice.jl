  using AcceleratorLattice
  @ele qq = Quadrupole(L = 4)
  @ele dd = Drift(L = 12)
  @ele ss = Solenoid(L = 1)
  @ele bb = BeginningEle(species_ref = species("proton"), pc_ref = 1e11)
  zline = beamline("z", [bb, qq, dd])
  lat = expand("lat", zline)
  create_external_ele(lat)
  superimpose!(ss, dd, offset = 0.2)
