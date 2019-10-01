open Time;;
open Temporal;;
open Effective_dating;;
(**
 * Work in Progress, but fleshes out a couple tricky challenges.
 *
 * Observe: Effective times are easier to represent with always-present values
 * (rather than allowing gaps in the timeline).  *
 *
 * Observe: The level of data-nesting at which Bitemporality is inserted doesn't
 * really matter. Obviously the code interacting with the data will need to know
 * whether Bitemporality is implemented at the top-level vs at individual values
 * but the Bitemporality module does not care.
 *
 * Possibility: Could allow clients to work directly with a transaction-time
 * snapshot. This might simplify the naming/API of the currently proposed
 * `historical_view_value`.
 *)
module Bitemporal = struct
  module type Value = sig
    type time
    type 'a bitemporal
    type effective_time = Effective of time
    type transaction_time = Transaction of time

    val at_time : transaction_time -> effective_time -> 'a bitemporal -> 'a option
    val current_value : 'a bitemporal -> 'a option
    (* To be implemented: *)
    (*
     * val value_at : effective_time -> 'a bitemporal -> 'a option
     * val historical_view_value : transaction_time -> 'a bitemporal -> 'a option
     *)

    val set_for_range : (effective_time * effective_time) -> 'a option -> 'a bitemporal -> 'a bitemporal
    val set_starting_at : effective_time -> 'a option -> 'a bitemporal -> 'a bitemporal
  end

  module Make (T:Time) : (Value with type time = T.time) = struct
    module Transacted = Temporal.Make(T)
    module Effective = EffectiveDating.Make(T)

    type time = T.time
    type effective_time = Effective of time
    type transaction_time = Transaction of time
    type 'a bitemporal = ('a Effective.timeline) Transacted.history

    let empty = Transacted.empty

    let at_time (transaction_time : transaction_time) (effective_time : effective_time) (timeline : 'a bitemporal) =
      let Transaction(ttime) = transaction_time in
      match Transacted.at_time timeline ttime with
      | Some(timeline) ->
          let Effective(etime) = effective_time in
          Effective.at_time etime timeline
      | None -> None

    let current_value timeline =
      let time = T.current_time () in
      let ttime = Transaction(time) in
      let etime = Effective(time) in
      at_time ttime etime timeline

    let set_for_range (effective_range : effective_time * effective_time) (value : 'a option) (timeline : 'a bitemporal) =
      let (Effective(effective_start), Effective(effective_end)) = effective_range in
      let ttime = T.current_time () in
      let new_inner_map =
        let inner_map =
          match Transacted.at_time timeline ttime with
          | Some(inner_map) -> inner_map
          | None -> Effective.empty
        in Effective.set_for_range (effective_start, effective_end) value inner_map
      in
      Transacted.set_now timeline new_inner_map

    let set_starting_at effective_start value timeline =
      set_for_range (effective_start, Effective(T.max_time)) value timeline
  end
end
