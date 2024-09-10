using AcceleratorLattice, Test
str_split(" a  b", " ")


@testset "str_split" begin
  @test str_split("a,b,, ", [",,"]) == ["a,b", ",,", " "]
  @test str_split("a,b,, ", [",,"], limit = 2) == ["a,b", ",, "]
  @test str_split("a,b,, ", [",,"], limit = 3) == ["a,b", ",,", " "]
  @test str_split(",a,', 'b,,", [","], keep_empty = true) == ["", ",", "a", ",", "', 'b", ",", "", ",", ""]
  @test str_split(",a,', 'b,,", [","]) == [",", "a", ",", "', 'b", ",", ","]
  @test str_split("a, b, c", ",", limit = 3) == ["a", ",", " b, c"]
  @test str_split(" a  b", " ") == ["a", " ", "b"]
  @test str_split("<< a< <  b<<x", ["<<", "<"], keep_empty = true) == ["", "<<", " a", "<", " ", "<", "  b", "<<", "x"]
  @test str_split("<< a< <  b<<x", ["<<", "<"]) == ["<<", " a", "<", " ", "<", "  b", "<<", "x"]
  @test str_split("<< a< <  b<<x", ["<<", "<", " "], keep_empty = true) ==
                                                ["", "<<", "", " ", "a", "<", "", " ", "", "<", "", " ", "b", "<<", "x"]
  @test str_split("<< a< <  b<<x", ["<<", "<", " "]) == ["<<", " ", "a", "<", " ", "<", " ", "b", "<<", "x"]
  @test str_split("a,b,, ", [",,"], limit = 1) == ["a,b,, "]
end;