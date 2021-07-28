using Actors
import Actors: newLink, spawn

inc!(a::Ref{Int}, c=0) = a[] += c

function dinc!(dict::Dict, key, by)
	count = get!(dict, key, 0)
	dict[key] = count + by
end
dinc!(dict) = copy(dict)

function link(lk, n)
	send(lk, n + 1)
	stop()
end

function chain(n::Int)
	start = newLink(1)
	lk = start
	for i in 1:n
		lk = spawn(link, lk)
	end
	send(lk, 0)
	receive(start)
end

## 
## The following is a basic implementation of a
## task chain (without actor overhead)
## 
counter(prev) = ch -> put!(prev, take!(ch) + 1)

function task_chain(n)
	start = Channel{Int}(1)
	ch = start
	for i in 1:n
		ch = Channel{Int}(counter(ch), spawn=true)
	end
	put!(ch, 0)
	take!(start)
end
