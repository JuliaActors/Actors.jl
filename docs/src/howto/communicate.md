# How to communicate with actors

An actor dispatches an incoming message 

- as a *communication* parameter to its behavior function or
- if it is a [`Msg`](@ref), it processes it according to the [message protocol](../manual/protocol.md).

Then it immediately proceeds to the next message if there is one or it waits for it. Therefore we have basically two ways to communicate with actors:

1. We [`send`](@ref) an actor a message invoking directly its behavior or
2. we send it a `Msg` causing it to follow the messaging protocol. We can do so by using the [user API](../api/user_api.md) functions.

## by sending

## receive

## use the messaging protocol

Normally we won't use the messaging protocol explicitly since we have the user API for that. But here we demonstrate how to do it.

The messaging protocol can be enhanced by a user (see below).

## use the user API functions

## write your own actor API

## enhance the messaging protocol
