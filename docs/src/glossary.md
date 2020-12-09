# A Glossary of Actor Terms

Since Gul Agha's actor glossary [^1] is very useful, we include here some of his descriptions and some additions.

| Actor term   | brief description |
|:-------------|:------------------|
| **acquaintance** | An actor ``\alpha`` is an acquaintance of an actor ``\beta`` if ``\beta`` knows the mail address of ``\alpha``. |
| **actor** | A computational agent which has an mail address and a behavior. Actors communicate by message-passing and carry out their actions concurrently. |
| **asynchronous communication** | Communication is considered to be asynchronous when the sender does not have to wait for the recipient to be ready to accept a communication before the sender can send the communication. |
| **behavior** | The behavior of an actor maps the incoming communication to a three tuple of tasks created, new actors created, and the replacement behavior. |
| **communication** | The only mechanism by which actors may affect each other's behavior. The content of a message sent by an actor is called a communication. |
| **concurrency** | The potentially parallel execution of actions without a determinate predefined sequence for their actions. |
| **customer** | A request communication contains the mail address of an actor called the customer to which a reply to the request is to be sent. Customers are dynamically created to carry out the rest of the computation, so that an actor sending a request to another actor can begin processing the next incoming communication without waiting for the subcomputations of the previous communication to complete. |
| **event** | In the actor model, an event is the acceptance of a communication by an actor. In response to accepting a communication, an actor creates other actors, sends communications and specifies a replacement behavior; in an event based semantics these actions are considered a part of the event. |
| **external actor** | An actor which is external to a configuration but whose mail address is known to some actor within the configuration. |
| **future** | A future is an actor representing the value of a computation in progress. Futures can speed up computation since they allow subcomputations using references to a value to proceed concurrently with the evaluation of an expression to compute the value. Communications sent to a future are queued until the value has been determined. |
| **mail address** | A virtual location by which an actor may be accessed. Each actor has a unique mail address which is invariant, although the behavior of an actor may change over time. |
| **mail queue** | The queue of incoming communications sent to a given actor. The mail queue represents the arrival order of communications and provides the means to buffer communications until they are processed by the target actor. |
| **receptionist** | An actor to whom communications may be sent from outside the configuration to which it belongs. The set of receptionists evolves dynamically as the mail addresses of various actors may be communicated to actors outside the system. |
| **replacement behavior** | A behavior specified by an actor processing a communication which is used to process the next communication in the mail queue of the actor. |
| **reply** | A communication sent in response to a request (see also customers). |
| **request** | A communication asking for a response to be sent to a customer contained in the request. |
| **synchronous communication** | Communication between two actors requiring the sender to wait until the recipient acknowledges or otherwise responds to the communication before continuing with further processing. Synchronous communication in actors is implemented using customers. |

[^1]: in: Gul Agha 1986. *Actors. a model of concurrent computation in distributed systems*, MIT; Appendix B
