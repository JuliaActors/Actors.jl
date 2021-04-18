# Checkpointing

```@meta
CurrentModule = Actors
```

A checkpointing actor can take user-defined checkpoints from current computations and restore them on demand.

```@docs
checkpointing
checkpoint
restore
register_checkpoint
@chkey
set_interval
get_interval
start_checkpointing
stop_checkpointing
get_checkpoints
save_checkpoints
load_checkpoints
```
