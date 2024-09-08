using AcceleratorLattice, Test

@ele beginning = BeginningEle(s = 0.3, pc_ref = 1e7, species_ref = species("electron"));
@ele qf = Quadrupole(L = 0.6, alias = "z1");
@ele qd = Quadrupole(L = 0.6, description = "z2");
@ele d = Drift(L = 0.4);
@ele d2 = Drift(L = -1.5);
@ele d3 = Drift(L = 2);
@ele b1 = Bend(L = 1.2);
@ele s1 = Sextupole(type = "abc");
@ele z1 = Bend(L = 0.02);
@ele z2 = Sextupole(L = 2.2, type = "abc");
@ele m1 = Marker(type = "qf");

ln1 = beamline("ln1", [qf, d]);
ln2 = beamline("ln2", [qd, d, qd], geometry = CLOSED, multipass = true);
ln3 = beamline("ln3", [beginning, d, b1, m1, d3])

fodo = beamline("fodo", [b1, s1, -2*ln1, m1, m1, ln2, reverse(qf), reverse(ln2), d2, reverse(beamline("sub", [qd, ln1]))]);

lat = expand("mylat", [(beginning, fodo), (beginning, ln2), ln3]);

#superimpose!(z2, lat.branch[3], offset = 0.1, ele_origin = BodyLoc.ENTRANCE_END)
superimpose!(z1, eles(lat, "1>>d#1"), offset = 0.1)


#---------------------------------------------------------------------------------------------------
# Notice element d2 has a negative length

b = lat.branch[1]

if false
@testset "ele_at_s" begin
  @test ele_at_s(b, b.ele[4].s, choose = StreamLoc.UPSTREAM_END).ix_ele == 2
  @test ele_at_s(b, b.ele[4].s, choose = StreamLoc.DOWNSTREAM_END).ix_ele == 4
  @test ele_at_s(b, b.ele[end].s_downstream, choose = StreamLoc.UPSTREAM_END).ix_ele == length(b.ele)-1
  @test ele_at_s(b, b.ele[end].s_downstream, choose = StreamLoc.DOWNSTREAM_END).ix_ele == length(b.ele)
  @test ele_at_s(b, b.ele[15].s, choose = StreamLoc.UPSTREAM_END, ele_near = b.ele[11]).ix_ele == 14
  @test ele_at_s(b, b.ele[15].s, choose = StreamLoc.DOWNSTREAM_END, ele_near = b.ele[11]).ix_ele == 15
  @test ele_at_s(b, b.ele[19].s, choose = StreamLoc.UPSTREAM_END, ele_near = b.ele[21]).ix_ele == 18
  @test ele_at_s(b, b.ele[19].s, choose = StreamLoc.DOWNSTREAM_END, ele_near = b.ele[21]).ix_ele == 19
end

@testset "eles" begin
  @test [e.ix_ele for e in eles(lat, "d")] == [4, 6, 18, 2]
  @test [e.ix_ele for e in eles(lat, "Marker::*")] == [8, 9, 21, 5]
  @test [e.ix_ele for e in eles(lat, "Marker::*-1")] == [7, 8, 20, 4]
  @test [e.ix_ele for e in eles(lat, "m1#2")] == [9]
  @test [e.ix_ele for e in eles(lat, "m1#2+1")] == [10]
  @test [e.ix_ele for e in eles(lat.branch[4], "d")] == [2]
  @test [(e.branch.ix_branch, e.ix_ele) for e in eles(lat, "multipass_lord>>d")] == [(4, 2)]
  @test [e.ix_ele for e in eles(lat, "%d")] == [20, 1, 3]
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
#  @test [e.ix_ele for e in ] == []
end

end