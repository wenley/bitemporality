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
module type History = sig
  module type Value = sig
    type time
    type 'a history
    val empty : 'a history
    val current_time : unit -> time
    val at_time : 'a history -> time -> 'a option
    val at_now : 'a history -> 'a option
    val set_now : 'a history -> 'a -> 'a history
  end

  module Make (T : Time) : Value with type time = T.time
end

module BaseHistory = struct
  module type Value = sig
    type time
    type 'a history
    val empty : 'a history
    val current_time : unit -> time
    val at_time : 'a history -> time -> 'a option
    val at_now : 'a history -> 'a option
    val set_now : 'a history -> 'a -> 'a history
  end
end

module MapHistory : History = struct
  include BaseHistory

  module Make (T:Time) : (Value with type time = T.time) = struct
    module TimeOrd : (Map.OrderedType with type t = T.time) = struct
      type t = T.time
      let compare = T.compare
    end

    module TMap : (Map.S with type key = T.time) = Map.Make(TimeOrd)

    type time = T.time
    type 'a history = 'a TMap.t

    let empty = TMap.empty
    let current_time = T.current_time
    let at_time history time =
      let result = TMap.find_last_opt (fun key_time -> key_time < time) history in
      match result with
      | Some(appended_at, value) -> Some(value)
      | None -> None
    let at_now history = at_time history (current_time ())

    (* Maybe-private method; useful also for reconstructing from serialized format *)
    let set_at history value time =
      TMap.add time value history

    let set_now history value = set_at history value (current_time ())
  end
end

module type Database = sig
  type table
end

module DatabaseHistory : History = struct
  include BaseHistory

  module Make (T:Time) (DB:Database) : (Value with type time = T.time) = struct
    type time = T.time
    type 'a history = DB.table

    let empty = DB.empty_table
    let current_time = T.current_time
  end
end

module type ImmutableDatabase = sig
  type record
  type row

  val serialize : record -> row
  val diff : record -> record -> row
  val commit : row -> unit
end
