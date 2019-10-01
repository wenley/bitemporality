open Time;;
(**
 * This is the publicly-facing API to wrap a value to have the idea of history.
 *
 * This only implements append-only behavior, which is exactly what we need for
 * transaction times.
 *
 * Observe: Transaction times are strictly ascending and append-only -> don't
 * need to bother with handling ranges. Once we begin having a view of the world,
 * we will always continue to have _some_ view of the world.
 *)
module type Temporal = sig
  module type Value = sig
    type time
    type 'a timed
    val empty : 'a timed
    val current_time : unit -> time
    val at_time : 'a timed -> time -> 'a option
    val at_now : 'a timed -> 'a option
    val set_now : 'a timed -> 'a -> 'a timed
  end

  module Make (T : Time) : Value with type time = T.time
end

module Temporal : Temporal = struct
  module type Value = sig
    type time
    type 'a timed
    val empty : 'a timed
    val current_time : unit -> time
    val at_time : 'a timed -> time -> 'a option
    val at_now : 'a timed -> 'a option
    val set_now : 'a timed -> 'a -> 'a timed

    (* This API is insufficient; does not allow for specifying arbitrary
    time-ranges for values; caller needs to reconstruct that API from these
    primitives *)
  end

  module type Time = sig
    type time
    val compare : time -> time -> int
    val current_time : unit -> time
  end

  module Make (T:Time) : (Value with type time = T.time) = struct
    module TimeOrd : (Map.OrderedType with type t = T.time) = struct
      type t = T.time
      let compare = T.compare
    end

    module TMap : (Map.S with type key = T.time) = Map.Make(TimeOrd)

    type time = T.time
    type 'a timed = 'a TMap.t

    let empty = TMap.empty
    let current_time = T.current_time
    let at_time timeline time =
      let result = TMap.find_last_opt (fun key_time -> key_time < time) timeline in
      match result with
      | Some(effective_since, value) -> Some(value)
      | None -> None
    let at_now timeline = at_time timeline (current_time ())

    let set_at timeline value time =
      TMap.add time value timeline
    let set_now timeline value = set_at timeline value (current_time ())
  end
end;;
