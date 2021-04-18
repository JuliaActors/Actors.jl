# Fault Tolerance

To use the above mechanisms for fault-tolerance successfully, supervisors, monitors or `:sticky` actors must have behaviors which are unlikely to fail. Therefore actors with complicated and error-prone behaviors should not be made monitors or `:sticky`.

Connections, monitors, supervisors and checkpoints represent quite different protocols. When do you use which?

1. If you want a failure in one actor to terminate others, then use [`connect`](@ref).
2. If instead you need to know or take action when some other actor or task exits for any reason, choose a [`monitor`](@ref).
3. If you want to restart actors or tasks on failure, use [`supervisor`](@ref)s.
4. Use [`checkpointing`](@ref) if you need to take checkpoints and to start or restart actors or tasks from previously taken ones.

The approaches can be combined to realize arbitrary hierarchies or structures of connected, monitored, supervised and checkpointed actors. This will be facilitated by actor framework libraries like [Supervisors.jl](https://github.com/JuliaActors/Supervisors.jl) and Checkpointing.jl.
