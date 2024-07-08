using AcceleratorLattice

@ele e_begin = BeginningEle(pc_ref = 1e9, species_ref = species("electron"));
@ele p_begin = BeginningEle(pc_ref = 1e11, species_ref = species("proton"));
@ele qd = Quadrupole(L = 0.6, Kn1 = -0.3);
@ele qf = Quadrupole(L = 0.6, x_rot = 2, alias = "qz", Ks8L = 123, tilt8 = 2);
@ele d = Drift(L = 0.6);
@ele b1 = Bend(L = 0.2, angle = 0.1);
@ele m = Marker();

# Define beamlines and lattice 

ln1 = beamline("ln1", [p_begin, qf, d]);
ln2 = beamline("ln2", [e_begin, qd, d, qd], geometry = closed);
lat = expand("mylat", [ln1, ln2]);

slave_list = [
  ctrl(absolute, "z1", :L, "2*vv+gg"),
  ctrl(delta, "z2", :Kn2l, "3*gg+vv"),
];

@ele c1 = Controller(slave = slave_list, variable = [var(:gg, 1, 2), var(:vv)]);
add_governor!(lat, c1);

superimpose!(b1, ref_ele = lat.branch[2].ele[3], offset = 0.2, ref_origin = entrance_end);
superimpose!(m, ref_ele = lat.branch[1].ele[1], offset = 0.2, ref_origin = entrance_end);

show(lat)
