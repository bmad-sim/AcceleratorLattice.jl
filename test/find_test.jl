using AcceleratorLattice, Test

@ele beginning = BeginningEle(s = 0.3, pc_ref = 1e7, species_ref = Species("electron"));
@ele qf = Quadrupole(L = 0.6, ID = "z1");
@ele qd = Quadrupole(L = 0.6, class = "z2");
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

lat = Lattice([bl([beginning, fodo], name = "fodo"), bl([beginning, ln2], name = "ln2"), ln3])

superimpose!(z2, lat.branch[3], offset = 0.1, ele_origin = BodyLoc.ENTRANCE_END)
superimpose!(z1, eles_search(lat, "1>>d")[1], offset = 0.1)

#---------------------------------------------------------------------------------------------------
# Notice element d2 has a negative length

b = lat.branch[1]
bsuper = lat.branch["super"]

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

@testset "eles_search" begin
  @test eles_search(lat, "d", order = Order.BY_S) == eles_search(lat, "fodo>>8, multipass>>2, fodo>>20")
  @test eles_search(lat, "Marker::*") == eles_search(lat, "fodo>>10, fodo>>11, fodo>>23, ln2>>5, ln3>>5, ln3>>8")
  @test eles_search(lat, "Marker::*-1") == eles_search(lat, "fodo>>9, fodo>>10, fodo>>22, ln2>>4, ln3>>4, ln3>>7")
  @test eles_search(lat.branch[5], "d") == eles_search(lat, "multipass>>2")
  @test eles_search(lat, "multipass>>d") == eles_search(lat, "multipass>>2")
  @test eles_search(lat, "%d") == eles_search(lat, "fodo>>22, multipass>>1, multipass>>3")
  @test eles_search(lat, "z1-1") == eles_search(lat, "1>>4")
  @test eles_search(b, "z1+1") == eles_search(lat, "fodo>>6")
  @test eles_search(lat, "z2-1") == eles_search(lat, "ln3>>2")
  @test eles_search(lat, "ID=`z1`") == eles_search(lat, "fodo>>7, fodo>>9, fodo>>15, fodo>>21")
  @test eles_search(lat, "ID=`z1` ~fodo>>9 ~fodo>>22") == eles_search(lat, "fodo>>7, fodo>>15, fodo>>21")
  @test eles_search(lat, "ID=`z1` & fodo>>9") == eles_search(lat, "fodo>>9")
  @test bsuper["z2"] == eles_search(lat, "super>>1")
  @test eles_search(lat, "Quadrupole::* ~*!*") == 
                eles_search(lat, "fodo>>7, fodo>>9, fodo>>15, fodo>>21, fodo>>22, multipass>>1, multipass>>3")
  @test eles_search(lat, "2>>2:4  ~Quadrupole::*") == [lat.branch[2].ele[3]]
  @test eles_search(lat, "2>>2:4") == lat.branch[2].ele[2:4]
  @test_throws ErrorException eles_search(lat, "quadrupole::*")   # quadrupole should be capitalized.
end

# !!! Test ele_at_offset with, EG multipass



# Function to print right-hand-side for "eles_search" testset. Used to create new tests. Just use the LHS as the argument.
#
#function toe(vec)
#  str = "eles_search(lat, \""
#  for ele in vec
#    str *= ele_name(ele, "!#") * ", "
#  end
#  print(str[1:end-2] * "\")")
#end;

