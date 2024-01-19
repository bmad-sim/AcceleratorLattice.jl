using AcceleratorLattice, Test

@ele begin_ln1 = BeginningEle(s = 0.3, pc_ref = 1e7, species_ref = species("electron"))

#@ele qf = Quadrupole(L = 0.6, K2 = 0.3, tilt0 = 1, x_pitch = 2, alias = "qz", E8sL = 123, Etilt8 = 2)
@ele qf = Quadrupole(L = 0.6, x_pitch = 2, alias = "qz", K8sL = 123, tilt8 = 2)
@ele qd = Quadrupole(L = 0.6, K1 = -0.3)
@ele d = Drift(L = 0.4)
@ele z1 = Bend(L = 1.2, angle = 0.001)
@ele z2 = Sextupole(K2L = 0.2)
@ele m1 = Marker()


ln1 = beamline("ln1", [qf, d])
ln2 = beamline("ln2", [qd, d, qd], geometry = Closed, multipass = true, begin_ele = begin_ln2)


fodo = beamline("fodo", [z1, z2, -2*ln1, m1, m1, ln2, reverse(qf), reverse(ln2), reverse(beamline("sub", [qd, ln1]))])

lat = expand("mylat", [ln2])


#-----------------------------

@testset "AcceleratorLattice.jl" begin
  @test ele_at_s(lat.branch[1], 0.3, true).ix_ele == 1
  @test ele_at_s(lat.branch[1], 0.3, false).ix_ele == 2
end
