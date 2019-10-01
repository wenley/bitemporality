
(* Client needs to provide a way to understand / interact with time *)
module type Time = sig
  type time
  val min_time : time
  val max_time : time
  val compare : time -> time -> int
  val current_time : unit -> time
end
