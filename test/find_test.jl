using AcceleratorLattice, Test

@ele beginning = BeginningEle(s = 0.3, pc_ref = 1e7, species_ref = species("electron"));
@ele qf = Quadrupole(L = 0.6, alias = "z1");
@ele qd = Quadrupole(L = 0.6, description = "z2");
@ele d = Drift(L = 0.4);
@ele d2 = Drift(L = -1.5);
@ele z1 = Bend(L = 1.2);
@ele z2 = Sextupole();
@ele m1 = Marker(type = "qf");


ln1 = beamline("ln1", [qf, d]);
ln2 = beamline("ln2", [qd, d, qd], geometry = closed, multipass = true);


fodo = beamline("fodo", [z1, z2, -2*ln1, m1, m1, ln2, reverse(qf), reverse(ln2), d2, reverse(beamline("sub", [qd, ln1]))]);

lat = expand("mylat", [(beginning, fodo), (beginning, ln2)]);


#---------------------------------------------------------------------------------------------------
# Notice element d2 has a negative length

b = lat.branch[1]

@testset "ele_at_s" begin
  @test ele_at_s(b, b.ele[4].s, choose = upstream_end).ix_ele == 2
  @test ele_at_s(b, b.ele[4].s, choose = downstream_end).ix_ele == 4
  @test ele_at_s(b, b.ele[end].s_downstream, choose = upstream_end).ix_ele == length(b.ele)-1
  @test ele_at_s(b, b.ele[end].s_downstream, choose = downstream_end).ix_ele == length(b.ele)
  @test ele_at_s(b, b.ele[15].s, choose = upstream_end, ele_near = b.ele[11]).ix_ele == 14
  @test ele_at_s(b, b.ele[15].s, choose = downstream_end, ele_near = b.ele[11]).ix_ele == 15
  @test ele_at_s(b, b.ele[19].s, choose = upstream_end, ele_near = b.ele[21]).ix_ele == 18
  @test ele_at_s(b, b.ele[19].s, choose = downstream_end, ele_near = b.ele[21]).ix_ele == 19
end

@testset "eles" begin
  @test [e.ix_ele for e in eles(lat, "d")] == [4, 6, 18, 2]
  @test [e.ix_ele for e in eles(lat, "Marker::*")] == [8, 9, 21, 5]
  @test [e.ix_ele for e in eles(lat, "Marker::*-1")] == [7, 8, 20, 4]
#  @test [e.ix_ele for e in 
#  @test [e.ix_ele for e in 
#  @test [e.ix_ele for e in 
#  @test [e.ix_ele for e in 
end

