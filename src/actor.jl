# This file is a part of Actors.jl, licensed under the MIT License (MIT).

export Actor
abstract Actor


export ActorMsgFrame
immutable ActorMsgFrame
    replyto::Actor
    message::Any
end


export ActorID
typealias ActorID UInt64


export ActorInbox
typealias ActorInbox Channel{Any}


export AbstractLocalActor
abstract AbstractLocalActor <: Actor


export LocalActor
immutable LocalActor <: AbstractLocalActor
   task::Task
end


export LocalActorAltInbox
immutable LocalActorAltInbox <: AbstractLocalActor
    actor::LocalActor
    inbox::ActorInbox
end


export ActorContext
immutable ActorContext
   id::ActorID
   inbox::ActorInbox
   self_ref::LocalActor
end

export actor_id
@inline actor_id(context::ActorContext) = context.id

export actor_inbox
@inline actor_inbox(context::ActorContext) = context.inbox

export localactor
@inline localactor(context::ActorContext) = context.self_ref


export actor_context
actor_context(task::Task) = task.storage[:_actor_context]::ActorContext

export actor_id
@inline actor_id(task::Task) = actor_id(actor_context(task))

export actor_inbox
@inline actor_inbox(task::Task) = actor_inbox(actor_context(task))

export localactor
@inline localactor(task::Task) = localactor(actor_context(task))


Base.show(io::IO, actor::LocalActor) = print(io, "local-actor-$(hex(actor_id(actor)))")
Base.show(io::IO, actor::LocalActorAltInbox) = print(io, "local-actor-alt-$(hex(actor_id(actor)))")

@inline Base.wait(actor::AbstractLocalActor) = wait(actor_task(actor))

function Serializer.serialize(s::SerializationState, actor::LocalActor)
    info("Serializing $actor (dummy implementation)")
    serialize(s, actor_id(actor))
end


export actor_task
@inline actor_task(actor::LocalActor) = actor.task

@inline actor_context(actor::AbstractLocalActor) = actor_context(actor_task(actor))
@inline actor_id(actor::AbstractLocalActor) = actor_id(actor_task(actor))

@inline actor_inbox(actor::LocalActor) = actor_inbox(actor_task(actor))

@inline actor_task(actor::LocalActorAltInbox) = actor_task(actor.actor)
@inline actor_inbox(actor::LocalActorAltInbox) = actor.inbox


function actorize_current_task(autoclose::Bool, chsize = 100)
    try
        task_local_storage(:_actor_context)::ActorContext
    catch
        const task = current_task()

        const id = rand(UInt64)
        const inbox = ActorInbox(chsize)
        const self_ref = LocalActor(task)
        const context = ActorContext(id, inbox, self_ref)
        task_local_storage(:_actor_context, context)

        autoclose && @schedule begin
            wait(task)
            close(context)
        end

        context::ActorContext
    end
end


self_context() = actorize_current_task(true)

export self
@inline self() = localactor(self_context())

@inline self_inbox() = actor_inbox(self_context())

self_with_alt_inbox(inbox::ActorInbox) = LocalActorAltInbox(self(), inbox)


export receive

function receive(inbox::ActorInbox)
    const message = take!(inbox)::ActorMsgFrame
    Pair(message.replyto, message.message)
end

receive() = receive(self_inbox())



function Base.close(context::ActorContext)
    close(actor_inbox(context))
end


function LocalActor(body)
    const contextch = Channel{ActorContext}(5)
    try
        const task = @schedule let
            const context = actorize_current_task(false)
            put!(contextch, context)
            try
                body()
            finally
                close(context)
            end
        end
        localactor(take!(contextch))
    finally
        close(contextch)
    end
end


export @actor
macro actor(body)
    quote
        LocalActor(() -> let
                $body
            end
        )
    end
end


export tell
tell(to::Actor, message::Any) = tell(to, message, self())


export ask
function ask(actor::Actor, msg::Any)
    const result = Ref{Any}()
    const queryactor = @actor begin
        tell(actor, msg)
        const x, reply = receive()
        result.x = reply
    end
    wait(queryactor)
    result.x
end



function tell(to::AbstractLocalActor, message::Any, replyto::Actor)
    try
        put!(actor_inbox(to), ActorMsgFrame(replyto, message))
    catch
        # info("Dead letter from $sender to $actor: $message")
    end
    return
end


function ask(actor::LocalActor, msg::Any)
    const tmp_inbox = ActorInbox(1)
    try
        tell(actor, msg, self_with_alt_inbox(tmp_inbox))
        x, reply = receive(tmp_inbox)
        reply
    finally
        close(tmp_inbox)
    end
end


function Base.kill(actor::LocalActor, exc = InterruptException())
    Base.throwto(actor_task(actor), exc)
    return
end


export NullActor
immutable NullActor <: Actor
end

@inline actor_id(::NullActor) = 0x0

Base.show(io::IO, actor::NullActor) = print(io, "null-actor")
Base.wait(actor::NullActor) = begin return end

tell(::NullActor, message::Any, replyto::Actor) = nothing
