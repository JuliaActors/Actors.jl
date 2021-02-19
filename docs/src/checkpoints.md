# Checkpointing

```@meta
CurrentModule = Actors
```

A checkpointing actor can take user-defined checkpoints from current computations and restore them on demand. It can save checkpoints to a file and reload them. It can be used by other actors to save and to restore state.

| API function | brief description |
|:-------------|:------------------|
| [`checkpointing`](@ref) | start a checkpointing actor, |
| [`checkpoint`](@ref) | tell it to take a checkpoint, |
| [`restore`](@ref) | tell it to restore the last checkpoint, |
| [`get_checkpoints`](@ref) | tell it to return a `Dict` of all checkpoints, |
| [`save_checkpoints`](@ref) | tell it to save the checkpoints to a file, |
| [`load_checkpoints`](@ref) | tell it to load them from a file. |
