using AcceleratorLattice

@ele e_begin = BeginningEle(pc_ref = 1e9, species_ref = species("electron"));
@ele p_begin = BeginningEle(pc_ref = 1e11, species_ref = species("proton"));
@ele qd = Quadrupole(L = 0.6, Kn1 = -0.3);
@ele qf = Quadrupole(L = 0.6, x_rot = 2, alias = "qz", Ks8L = 123, tilt8 = 2);
@ele d = Drift(L = 0.6);
@ele b1 = Bend(L = 0.2, angle = 0.1);
@ele m = Marker();

# Define beamlines and lattice 

ln1 = BeamLine([p_begin, qf, d]);
ln2 = BeamLine([e_begin, qd, d, qd], geometry = closed);
lat = Lattice([ln1, ln2]);

superimpose!(b1, ref_ele = lat.branch[2].ele[3], offset = 0.2, ref_origin = entrance_end);
superimpose!(m, ref_ele = lat.branch[1].ele[1], offset = 0.2, ref_origin = entrance_end);

show(lat)
