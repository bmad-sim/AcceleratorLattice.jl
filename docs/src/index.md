# AcceleratorLattice.jl

*Lattice instantiation and manipulation for high energy particle accelerators.*

Part of the Bmad-Julia project for simulations of charged-particle and X-rays
in accelerators and storage rings. 

This documentation serves as an introduction and quick reference guide to `AcceleratorLattice.jl`.
The depth manual can be found the `Tracking Packages` section.

## Overview

With the `AcceleratorLattice.jl` package accelerator lattices can be constructed and manipulated.
This does not include tracking. Packages that implement tracking are listed in [Tracking Packages]

## Nomenclature

- `Element`: Lattice elements are the basic building block for describing an accelerator. Lattice elements are structs that inherit from the abstract type `Lat`. Example element structs are `Quadrupole` and `RFCavity`.

- `Branch`: A lattice branch is essentially an array of lattice elements. All branches are of type  `Branch`. Branches come in two types: There are "tracking" branches through which particles can be tracked and there are "lord" branches which hold a collection of "lord" elements which are elements can control the parameters of other elements but are not tracked through directly. 

- `lattice`: A lattice is an array of branches. All lattices are of type `Lat`. Tracking branches can be connected together to form an entire accelerator complex. For example, a branch representing an injection line can be connected to a branch representing a storage ring and there can be multiple branches representing extraction lines connected to the storage ring branch.

## Setup

## Basic Usage

## Tracking Packages

Since Bmad-Julia is in the initial stages of development, currently there are no packages for tracking.

## Cheat Sheet

Functions and Structs sorted by functionality.

## Programming conventions

Follow general Julia programming conventions with two spaces per indent.

Non-ASCII characters in code can be problematical in that some of them are hard to decipher and,
depending upon the editor being used, hard to type. So use of non-ASCII characters should be
avoided unless the use is clearly beneficial. One example of acceptable use is the notin character "∉" since
there is no ASCII equivalent. 