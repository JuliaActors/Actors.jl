# `Actors` News 

## v0.1.5

`Func` has been renamed to `Bhv` since that is more to the point.

## v0.1.4

Bugfix in `onmessage` actor mode dispatch

## v0.1.3

### Name Changes

For upcoming compatibility with `ActorInterfaces.Classic` the name of an actor primitive has been changed to `send` and consequently API functions have been renamed to `receive`, `request`, `call`, `cast`, `exec`, `query` (all now without exclamation mark).

### Actor Mode

An actor mode has been introduced to allow other libraries to implement a different onmessage protocol following API calls like `init!`, `call`, `cast`, `exit!`. This will allow to build an actor infrastructure.

### Registry

A registry has been added for actors to register and to be callable by name.

### Behavior Improvements

`Func` is now much faster and documentation is much clearer.

2020-11-30, pb
