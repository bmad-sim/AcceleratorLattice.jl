using Bmad
using Test

qf = latele(Quadrupole, "qf", l = 0.6, k1 = 0.3)
d  = latele(Drift, "d", l = 0.4)
qd = latele(Quadrupole, "qd", l = 0.6, k1 = -0.3)

ln1 = beamline("ln1", [qf, d])
ln2 = beamline("ln2", [qd, d, qd], multipass = true)
ln  = beamline("fodo", [-2*ln1, ln2, reverse(qf), reverse(ln2), reverse(beamline("sub", [qd, ln1]))])
root_beamline = ln

lat = lat_expansion([ln, ln2], "mylat")

#-----------------------------

@testset "Bmad.jl" begin
  @test 2 == 2
  @test 2 ≈ 3 atol = 2
end
