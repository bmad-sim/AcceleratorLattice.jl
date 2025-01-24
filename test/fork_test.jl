using AcceleratorLattice, Test

@ele begin1 = BeginningEle(species_ref = Species("electron"), pc_ref = 1e6)
@ele begin2 = BeginningEle(species_ref = Species("proton"), pc_ref = 1e7)
@ele begin3 = BeginningEle(species_ref = Species("photon"), E_tot_ref = 1e3)
@ele mk1 = Marker()
@ele bend1 = Bend(g = 1, angle = pi/2, Kn2L = 0.1, Bs3 = 0.2, En4 = 0.3, Es5L = 0.4)
@ele dft = Drift(L = 2)
bend2 = copy(bend1)
bend2.name = "bend2"
bend2.tilt_ref = pi/2

@ele fork1 = Fork()
@ele fork2 = Fork(propagate_reference = false)
@ele fork3 = Fork(to_ele = "mk1")

line1 = BeamLine([begin1, bend1, fork1, mk1])
line2 = BeamLine([begin2, bend2])
line3 = BeamLine([begin3, dft, fork3])

fork1.to_line = line2
fork2.to_line = line3

lat = Lattice([line1])

superimpose!(fork2, lat["bend2"], offset = 0.2)

b1 = lat.branch[1]
b2 = lat.branch[2]



@testset "bend_bookkeeping" begin


end

# test fork superimpose
# test fork with multipass
# test fork to existing branch.
# make sure finite L throws error.
# check that forked to branch inherits reference energy from fork.
# Restriction? If forking to a new branch, must fork to beginning of branch.
# Check that changes in reference or floor at fork gets propagated to to-branch.