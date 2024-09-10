using AcceleratorLattice, Test


@testset "str_split" begin
  @test str_split("a,b,, ", [",,"]) == ["a,b", ",,", " "]
  @test str_split("a,b,, ", [",,"], limit = 2) == ["a,b", ",, "]
  @test str_split("a,b,, ", [",,"], limit = 3) == ["a,b", ",,", " "]
  @test str_split(",a,', 'b,,", [","]) == ["", ",", "a", ",", "', 'b", ",", "", ",", ""]
  @test str_split("a, b, c", ",", limit = 3) == ["a", ",", " b, c"]
  @test str_split(" a  b", " ") == ["a", " ", "b"]
  @test str_split("<< a< <  b<<x", ["<<", "<"]) == ["", "<<", " a", "<", " ", "<", "  b", "<<", "x"]
  @test str_split("<< a< <  b<<x", ["<<", "<", " "]) == ["", "<<", "", " ", "a", "<", "", " ", "", "<", "", " ", "b", "<<", "x"]
  @test str_split("a,b,, ", [",,"], limit = 1) == ["a,b,, "]
end;