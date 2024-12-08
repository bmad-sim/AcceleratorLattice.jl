using AcceleratorLattice, Test

s = Species("electron")

@testset "conversion" begin
  @test calc_pc(s, E_tot = calc_E_tot(s, pc = 1e4)) ≈ 1e4
  @test calc_pc(s, β = calc_β(s, pc = 1e4)) ≈ 1e4
  @test calc_pc(s, E_kinetic = calc_E_kinetic(s, pc = 1e4)) ≈ 1e4
  @test calc_pc(s, γ = calc_γ(s, pc = 1e4)) ≈ 1e4

  @test calc_pc(s, E_tot = calc_E_tot(s, pc = 1e12)) ≈ 1e12
  @test calc_pc(s, E_kinetic = calc_E_kinetic(s, pc = 1e12)) ≈ 1e12
  @test calc_pc(s, γ = calc_γ(s, pc = 1e12)) ≈ 1e12

  @test calc_E_tot(s, pc = calc_pc(s, E_tot = 6e5)) ≈ 6e5
  @test calc_E_tot(s, β = calc_β(s, E_tot = 6e5)) ≈ 6e5
  @test calc_E_tot(s, E_kinetic = calc_E_kinetic(s, E_tot = 6e5)) ≈ 6e5
  @test calc_E_tot(s, γ = calc_γ(s, E_tot = 6e5)) ≈ 6e5

  @test calc_E_tot(s, pc = calc_pc(s, E_tot = 1e12)) ≈ 1e12
  @test calc_E_tot(s, E_kinetic = calc_E_kinetic(s, E_tot = 1e12)) ≈ 1e12
  @test calc_E_tot(s, γ = calc_γ(s, E_tot = 1e12)) ≈ 1e12

  @test calc_E_kinetic(s, E_tot = calc_E_tot(s, E_kinetic = 1e4)) ≈ 1e4
  @test calc_E_kinetic(s, β = calc_β(s, E_kinetic = 1e4)) ≈ 1e4
  @test calc_E_kinetic(s, pc = calc_pc(s, E_kinetic = 1e4)) ≈ 1e4
  @test calc_E_kinetic(s, γ = calc_γ(s, E_kinetic = 1e4)) ≈ 1e4

  @test calc_β(s, E_tot = calc_E_tot(s, β = 0.1)) ≈ 0.1
  @test calc_β(s, pc = calc_pc(s, β = 0.1)) ≈ 0.1
  @test calc_β(s, E_kinetic = calc_E_kinetic(s, β = 0.1)) ≈ 0.1
  @test calc_β(s, γ = calc_γ(s, β = 0.1)) ≈ 0.1

  @test calc_β(s, E_tot = calc_E_tot(s, β = 0.9999)) ≈ 0.9999
  @test calc_β(s, pc = calc_pc(s, β = 0.9999)) ≈ 0.9999
  @test calc_β(s, E_kinetic = calc_E_kinetic(s, β = 0.9999)) ≈ 0.9999
  @test calc_β(s, γ = calc_γ(s, β = 0.9999)) ≈ 0.9999

  @test calc_β1(s, E_tot = calc_E_tot(s, β = 1 - 1e-6)) ≈ 1e-6
  @test calc_β1(s, pc = calc_pc(s, β = 1 - 1e-6)) ≈ 1e-6
  @test calc_β1(s, E_kinetic = calc_E_kinetic(s, β = 1 - 1e-6)) ≈ 1e-6
  @test calc_β1(s, γ = calc_γ(s, β = 1 - 1e-6)) ≈ 1e-6

  @test calc_γ(s, pc = calc_pc(s, γ = 1.0001)) ≈ 1.0001
  @test calc_γ(s, β = calc_β(s, γ = 1.0001)) ≈ 1.0001
  @test calc_γ(s, E_kinetic = calc_E_kinetic(s, γ = 1.0001)) ≈ 1.0001
  @test calc_γ(s, E_tot = calc_E_tot(s, γ = 1.0001)) ≈ 1.0001

  @test calc_γ(s, pc = calc_pc(s, γ = 1e12)) ≈ 1e12
  @test calc_γ(s, E_kinetic = calc_E_kinetic(s, γ = 1e12)) ≈ 1e12
  @test calc_γ(s, E_tot = calc_E_tot(s, γ = 1e12)) ≈ 1e12
end