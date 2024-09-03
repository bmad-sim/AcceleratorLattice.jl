using AcceleratorLattice
@ele qq = Quadrupole(L = 4, Kn1 = 0.34)
@ele dd = Drift(L = 12)
@ele ss = Solenoid(L = 1)
@ele zz = Solenoid(L = 1)
@ele bb = BeginningEle(species_ref = species("proton"), pc_ref = 1e11)

zline = beamline("z", [bb, qq, dd]);
zline = beamline("z", [bb, dd]);
lat = expand("lat", zline);

show(lat)

ref_ele = eles(lat, "dd")[1];
superimpose!(ss, ref_ele, offset = 0.2);
#ref_ele = eles(lat, "ss")[1];
#superimpose!(zz, [ref_ele], offset = 0.2);

show(lat)
