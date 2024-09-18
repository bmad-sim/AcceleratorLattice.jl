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

@testset "str_match" begin
  @test str_match("*ab", "figab") == true
  @test str_match("*ab", "figabc") == false
  @test str_match("%c", "zc") == true
  @test str_match("c%", "cz") == true
  @test str_match("c%", "czz") == false
  @test str_match("c\\*", "c*") == true
  @test str_match("c\\*", "c*c") == false
  @test str_match("\\%", "%") == true
  @test str_match("\\%", "z") == false
end;

@testset "str_other" begin
  @test str_quote("abc") == "\"abc\""
  @test str_unquote("'abc'") == "abc"
  @test str_unquote("`abc`") == "abc"
  @test str_unquote("`abc'") == "`abc'"
  @test integer("-7") == -7
  @test integer("", "bad") == "bad"
  @test integer("1 3", "bad") == "bad"
end;
