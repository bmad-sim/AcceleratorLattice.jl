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

bl = BeamLine
ln3 = bl([beginning, d, b1, m1, d3], name = "ln3")
ln1 = bl([qf, d])
ln2 = bl([qd, d, qd], geometry = CLOSED, multipass = true)
fodo = bl([b1, s1, -2*ln1, m1, m1, ln2, reverse(qf), reverse(ln2), d2, reverse(bl([qd, ln1]))])

lat = expand("mylat", [bl([beginning, fodo], name = "fodo"), bl([beginning, ln2], name = "ln2"), ln3])

superimpose!(z2, lat.branch[3], offset = 0.1, ele_origin = BodyLoc.ENTRANCE_END)
superimpose!(z1, eles(lat, "1>>d#1"), offset = 0.1)

#---------------------------------------------------------------------------------------------------
# Notice element d2 has a negative length

b = lat.branch[1]

# !!! Test ele_at_offset with, EG multipass


@testset "ele_at_s" begin
  @test ele_at_s(b, b.ele[4].s, select = Select.UPSTREAM) === b.ele[2]
  @test ele_at_s(b, b.ele[4].s, select = Select.DOWNSTREAM) === b.ele[4]
  @test ele_at_s(b, b.ele[end].s_downstream, select = Select.UPSTREAM) === b.ele[end-1]
  @test ele_at_s(b, b.ele[end].s_downstream, select = Select.DOWNSTREAM) === b.ele[end]
  @test ele_at_s(b, b.ele[17].s, select = Select.UPSTREAM, ele_near = b.ele[11]) == b.ele[16]
  @test ele_at_s(b, b.ele[17].s, select = Select.DOWNSTREAM, ele_near = b.ele[11]) == b.ele[17]
  @test ele_at_s(b, b.ele[21].s, select = Select.UPSTREAM, ele_near = b.ele[21]) == b.ele[20]
  @test ele_at_s(b, b.ele[21].s, select = Select.DOWNSTREAM, ele_near = b.ele[21]) == b.ele[21]
end

@testset "eles" begin
  @test eles(lat, "d") == eles(lat, "fodo>>8, fodo>>20, multipass_lord>>2")
  @test eles(lat, "Marker::*") == eles(lat, "fodo>>10, fodo>>11, fodo>>23, ln2>>5, ln3>>5, ln3>>8")
  @test eles(lat, "Marker::*-1") == eles(lat, "fodo>>9, fodo>>10, fodo>>22, ln2>>4, ln3>>4, ln3>>7")
  @test eles(lat, "m1#2") == eles(lat, "fodo>>11")
  @test eles(lat, "m1#2+1") == eles(lat, "fodo>>12")
  @test eles(lat.branch[5], "d") == eles(lat, "multipass_lord>>2")
  @test eles(lat, "multipass_lord>>d") == eles(lat, "multipass_lord>>2")
  @test eles(lat, "%d") == eles(lat, "fodo>>22, multipass_lord>>1, multipass_lord>>3")
  @test eles(lat, "z1-1") == eles(lat, "1>>4")
  @test eles(lat, "z1+1") == eles(lat, "fodo>>6")
  @test eles(lat, "z2-1") == eles(lat, "ln3>>2")
  @test eles(lat, "alias=`z1`") == eles(lat, "fodo>>7, fodo>>9, fodo>>15, fodo>>21")
  @test eles(lat, "alias=`z1` ~fodo>>9 ~fodo>>22") == eles(lat, "fodo>>7, fodo>>15, fodo>>21")
  @test eles(lat, "alias=`z1` & fodo>>9") == eles(lat, "fodo>>9")
  @test b["z1"] == eles(lat, "super_lord>>3")
  @test eles(lat, "Quadrupole::* ~*!*") == 
                eles(lat, "fodo>>7, fodo>>9, fodo>>15, fodo>>21, fodo>>22, multipass_lord>>1, multipass_lord>>3")
  @test_throws ErrorException eles(lat, "quadrupole::*")
end

# Function to print right-hand-side for "eles" testset. Used to create new tests. Just use the LHS as the argument.
#
#function toe(vec)
#  str = "eles(lat, \""
#  for ele in vec
#    str *= ele_name(ele, "!#") * ", "
#  end
#  print(str[1:end-2] * "\")")
#end;

