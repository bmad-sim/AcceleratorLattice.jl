using AcceleratorLattice, Test

@ele beginning = BeginningEle(s = 0.3, pc_ref = 1e7, species_ref = species("electron"));
@ele qf = Quadrupole(L = 0.6, alias = "qz");
@ele qd = Quadrupole(L = 0.6);
@ele d = Drift(L = 0.4);
@ele z1 = Bend(L = 1.2);
@ele z2 = Sextupole();
@ele m1 = Marker();


ln1 = beamline("ln1", [qf, d]);
ln2 = beamline("ln2", [qd, d, qd], geometry = closed, multipass = true);


fodo = beamline("fodo", [z1, z2, -2*ln1, m1, m1, ln2, reverse(qf), reverse(ln2), reverse(beamline("sub", [qd, ln1]))]);

lat = expand("mylat", [[beginning, fodo], [beginning, ln2]]);


#---------------------------------------------------------------------------------------------------

@testset "ele_at_s" begin
  @test ele_at_s(lat.branch[1], 0.3, true).ix_ele == 1
  @test ele_at_s(lat.branch[1], 0.3, false).ix_ele == 2
end
