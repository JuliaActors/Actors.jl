# Fault Tolerance

To use the above mechanisms for fault-tolerance successfully, supervisors, monitors or `:sticky` actors must have behaviors which are unlikely to fail. Therefore actors with complicated and error-prone behaviors should not be made monitors or `:sticky`.

Connections, monitors and supervisors represent quite different protocols. When do you use which?

1. If you want a failure in one actor to terminate others, then use [`connect`](@ref).
2. If instead you need to know or take action when some other actor or task exits for any reason, choose a monitor.
3. If you want to realize a hierarchy of actors and tasks, use supervisors.

The approaches can be combined to realize arbitrary structures of connected and monitored actors.

