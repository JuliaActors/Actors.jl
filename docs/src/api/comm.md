# Communication primitives

To receive a reply from an actor there are two possibilities:

1. *asynchronous* bidirectional communication and
2. *synchronous* bidirectional communication.

| API function | brief description |
|:-------------|:------------------|
| [`receive`](@ref) | after a [`send`](@ref) receive the [`Response`](@ref) asynchronously |
| [`request`](@ref) | `send` (implicitly) a message to an actor, **block** and `receive` the result synchronously |

## Functions

```@docs
receive
request
```
