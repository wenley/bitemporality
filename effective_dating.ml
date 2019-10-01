(**
 * This implements arbitrary history rewriting, as well as having sections of
 * time where no value exists.
 *
 * The logic is easier to represent with always-present values (rather than
 * allowing the underlying representation to have gaps in the timeline; a sparse
 * representation). This is the difference between 'a timeline being
 * - `'a TRangeMap.t` (use absent keys to represent no-value)
 * `'a option TRangeMap.t` (use explicit None to represent no-value)
 *
 * Choosing to always have a value for all time makes the logic easier in
 * set_for_range, since it can always rely on a front-neighbor-range and a
 * back-neighbor-range to exist. (Without this, I would need to call
 * `TRangeMap.find_opt` and do another layer of pattern matching rather than
 * the current, simpler `TRangeMap.find`).
 *)
module EffectiveDating = struct
  module type Value = sig
    type time
    type 'a timeline

    val at_time : effective_time -> 'a timeline -> 'a option
    val current_value : 'a timeline -> 'a option

    val set_for_range : (effective_time * effective_time) -> 'a option -> 'a timeline -> 'a timeline
  end

  module Make (T:Time) : (Value with type time = T.time) = struct
    module TimeRangeOrd : (Map.OrderedType with type t = (T.time * T.time)) = struct
      type t = (T.time * T.time)
      let compare t1 t2 =
        (* Double-check this for expected behavior / contract *)
        let (start1, end1) = t1 in
        let (start2, end2) = t2 in
        if start1 = start2
        then end1 - end2
          else start1 - start2
    end
    module TRangeMap : (Map.S with type key = (T.time * T.time)) = Map.Make(TimeRangeOrd)

    type time = T.time
    type 'a timeline = 'a option TRangeMap.t

    let empty = TRangeMap.empty |>
      (TRangeMap.add (Effective(T.min_time), Effective(T.max_time)) None)

    let contains_time (time : T.time) ((start : T.time), (stop : T.time)) =
      (* TODO: Double-check this for consistent boundaries *)
      let after_start = T.compare start time < 0 in
      let before_end = T.compare stop time < 0 in
      after_start && before_end

    let at_time (effective_time : time) (timeline : 'a timeline) =
      let (effective_since, value) = TRangeMap.find (contains_time etime) inner_map in
      value

    let current_value = at_time (T.current_time ()) timeline

    let set_for_range effective_range value timeline =
      let (effective_start, effective_end) = effective_range in
      let ((old_start, _), before_value) = TRangeMap.find (contains_time effective_start) inner_map in
      let ((_, old_end), after_value) = TRangeMap.find (contains_time effective_end) inner_map in
      let clean_map =
        let not_touching_effective_range (start, stop) =
          (stop <= effective_start) || (start >= effective_end)
        in TRangeMap.filter not_touching_effective_range inner_map
      in
      clean_map |>
      (TRangeMap.add (old_start, effective_start) before_value) |>
      (TRangeMap.add (effective_end, old_end) after_value) |>
      (TRangeMap.add effective_range value)
  end
end
