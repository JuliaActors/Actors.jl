# Monitors

```@meta
CurrentModule = Actors
```

An actor can be told to [`monitor`](@ref) other actors or Julia tasks. Monitored actors or tasks send a [`Down`](@ref) message with an exit reason to their monitor(s) before they terminate. A monitor then gives a warning or executes a specified action dispatched on the received reason.

![monitor](../assets/monitor.svg)

Monitors do not forward `Down` messages. They give warnings or execute specified actions for `Down` signals (even with reason `:normal`). Monitoring is not bidirectional. If a monitor fails, the monitored actor gets no notification. Monitoring can be stopped with [`demonitor`](@ref). An actor can have several monitors (if that makes sense).
