(*
 * oBus_peer.ml
 * ------------
 * Copyright : (c) 2008, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of obus, an ocaml implementation of D-Bus.
 *)

open Lwt_react
open Lwt

type t = {
  connection : OBus_connection.t;
  name : OBus_name.bus;
}

let compare = Pervasives.compare

let connection p = p.connection
let name p = p.name

let make ~connection ~name = { connection = connection; name = name }
let anonymous c = { connection = c; name = "" }

let ping peer =
  lwt reply, () =
    OBus_connection.method_call_with_message
      ~connection:peer.connection
      ~destination:OBus_protocol.bus_name
      ~path:[]
      ~interface:"org.freedesktop.DBus.Peer"
      ~member:"Peer"
      ~i_args:OBus_value.C.seq0
      ~o_args:OBus_value.C.seq0
      ()
  in
  return { peer with name = OBus_message.sender reply }

let get_machine_id peer =
  lwt mid =
    OBus_connection.method_call
      ~connection:peer.connection
      ~destination:OBus_protocol.bus_name
      ~path:[]
      ~interface:"org.freedesktop.DBus.Peer"
      ~member:"GetMachineId"
      ~i_args:OBus_value.C.seq0
      ~o_args:(OBus_value.C.seq1 OBus_value.C.basic_string)
      ()
  in
  try
    return (OBus_uuid.of_string mid)
  with exn ->
    raise_lwt exn

let wait_for_exit peer =
  match peer.name with
    | "" ->
        raise_lwt (Invalid_argument "OBus_peer.wait_for_exit: peer has no name")
    | name ->
        let switch = Lwt_switch.create () in
        lwt owner = OBus_resolver.make ~switch peer.connection name in
        if S.value owner = "" then
          Lwt_switch.turn_off switch
        else
          try_lwt
            lwt _ = E.next (E.filter ((=) "") (S.changes owner)) in
            return ()
          finally
            Lwt_switch.turn_off switch

(* +-----------------------------------------------------------------+
   | Private peers                                                   |
   +-----------------------------------------------------------------+ *)

type peer = t

module type Private = sig
  type t = private peer
  external of_peer : peer -> t = "%identity"
  external to_peer : t -> peer = "%identity"
end

module Private =
struct
  type t = peer
  external of_peer : peer -> t = "%identity"
  external to_peer : t -> peer = "%identity"
end
