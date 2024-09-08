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

superimpose!(z2, lat.branch[3], offset = 0.1, ele_origin = BodyLoc.ENTRANCE_END)
superimpose!(z1, eles(lat, "1>>d#1"), offset = 0.1)

eles(lat, "z1+1")

#---------------------------------------------------------------------------------------------------
# Notice element d2 has a negative length

b = lat.branch[1]

@testset "ele_at_s" begin
  @test ele_at_s(b, b.ele[4].s, select = Select.UPSTREAM).ix_ele == 2
  @test ele_at_s(b, b.ele[4].s, select = Select.DOWNSTREAM).ix_ele == 4
  @test ele_at_s(b, b.ele[end].s_downstream, select = Select.UPSTREAM).ix_ele == length(b.ele)-1
  @test ele_at_s(b, b.ele[end].s_downstream, select = Select.DOWNSTREAM).ix_ele == length(b.ele)
  @test ele_at_s(b, b.ele[17].s, select = Select.UPSTREAM, ele_near = b.ele[11]).ix_ele == 16
  @test ele_at_s(b, b.ele[17].s, select = Select.DOWNSTREAM, ele_near = b.ele[11]).ix_ele == 17
  @test ele_at_s(b, b.ele[21].s, select = Select.UPSTREAM, ele_near = b.ele[21]).ix_ele == 20
  @test ele_at_s(b, b.ele[21].s, select = Select.DOWNSTREAM, ele_near = b.ele[21]).ix_ele == 21
end

@testset "eles" begin
  @test [e.ix_ele for e in eles(lat, "d")] == [8, 20, 2]
  @test [e.ix_ele for e in eles(lat, "Marker::*")] == [10, 11, 23, 5, 5, 8]
  @test [e.ix_ele for e in eles(lat, "Marker::*-1")] == [9, 10, 22, 4, 4, 7]
  @test [e.ix_ele for e in eles(lat, "m1#2")] == [11]
  @test [e.ix_ele for e in eles(lat, "m1#2+1")] == [12]
  @test [e.ix_ele for e in eles(lat.branch[5], "d")] == [2]
  @test [(e.branch.ix_branch, e.ix_ele) for e in eles(lat, "multipass_lord>>d")] == [(5, 2)]
  @test [e.ix_ele for e in eles(lat, "%d")] == [22, 1, 3]
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
