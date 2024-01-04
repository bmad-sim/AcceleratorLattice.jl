@ele begin_ln2 = BeginningEle(pc_ref = 1e7, species_ref = species("electron"))
@ele begin_fodo = BeginningEle(E_tot_ref = 1.23456789012345678e3, s = 0.3, species_ref = species("photon"))
#@ele qf = Quadrupole(L = 0.6, K2 = 0.3, tilt0 = 1, x_pitch = 2, alias = "qz", E8sL = 123, Etilt8 = 2)
@ele qf = Quadrupole(L = 0.6, x_pitch = 2, alias = "qz", K8sL = 123, tilt8 = 2)
@ele qd = Quadrupole(L = 0.6, K1 = -0.3)
@ele d = Drift(L = 0.4)
@ele z1 = Bend(L_chord = 1.2, angle = 0.001)
@ele z2 = Sextupole(K2L = 0.2)
@ele m1 = Marker()


ln1 = beamline("ln1", [qf, d])
ln2 = beamline("ln2", [qd, d, qd], geometry = Closed, multipass = true, begin_ele = begin_ln2)
fodo = beamline("fodo", [z1, z2, -2*ln1, m1, ln2, reverse(qf), reverse(ln2), reverse(beamline("sub", [qd, ln1]))])

lat = expand("mylat", [beamline("fodo2", [fodo], begin_ele = begin_fodo), ln2])
