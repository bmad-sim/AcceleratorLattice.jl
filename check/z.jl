using AcceleratorLattice
@ele qq = Quadrupole(L = 4, Kn1 = 0.34)
@ele dd = Drift(L = 12)
@ele ss = Solenoid(L = 2, Bn3L = 1, Ks4 = 2, En3L = 3, Es4 = 4, ID = "abc")
@ele zz = Solenoid(L = 1)
@ele bb = BeginningEle(species_ref = Species("proton"), pc_ref = 1e11)

bl = BeamLine
zline = bl([bb, qq, dd]);
zline = bl([bb, dd]);
lat = Lattice([zline]);

#show(lat)

ref_ele = eles(lat, "dd")[1];
superimpose!(ss, ref_ele, offset = 0.2);
lat["ss"][1].type = "zzz"

#ref_ele = eles(lat, "ss")[1];
#superimpose!(zz, [ref_ele], offset = 0.2);

show(lat)
