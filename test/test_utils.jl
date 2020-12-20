#
# This file is part of the Actors.jl Julia package, 
# MIT license, part of https://github.com/JuliaActors
#

using Actors, Test

@msg Msg A B C
@test supertype(A) == Msg
@test supertype(B) == Msg
@test supertype(C) == Msg

@msg D E F
@test supertype(D) == Any
@test supertype(E) == Any
@test supertype(F) == Any
