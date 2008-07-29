(*
 * oBus_header.mli
 * ---------------
 * Copyright : (c) 2008, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of obus, an ocaml implemtation of dbus.
 *)

(** Message description *)

type serial = int32

(** Message types with their recquired/optinnal parameters *)

type path = OBus_path.t
type interface = string
type member = string
type error_name = string
type reply_serial = serial

type method_call_type =
    [ `Method_call of path * interface option * member ]

type method_return_type =
    [ `Method_return of reply_serial ]

type error_type =
    [ `Error of reply_serial * error_name ]

type signal_type =
    [ `Signal of path * interface * member ]

type message_type =
    [ method_call_type
    | method_return_type
    | error_type
    | signal_type ]

(** flags *)
type flags = {
  no_reply_expected : bool;
  no_auto_start : bool;
}

val no_reply_expected : flags -> bool
val no_auto_start : flags -> bool

val make_flags : ?no_reply_expected:bool -> ?no_auto_start:bool -> unit -> flags
  (** Optionnal arguments default to true *)

val default_flags : flags
  (** All false *)

type 'typ t = {
  flags : flags;
  serial : serial;
  typ : 'typ;
  destination : string option;
  sender : string option;
}
constraint 'typ = [< message_type ]

type method_call = method_call_type t
type method_return = method_return_type t
type signal = signal_type t
type error = error_type t
type any = message_type t

val flags : 'a t -> flags
val serial : 'a t -> serial
val typ : 'a t -> 'a
val destination : 'a t -> string option
val sender : 'a t -> string option

(** {6 Creation of header} *)

(** Note that when creating an header the serial field is not
    relevant, it is overridden at sending-time *)

val make :
  ?flags:flags ->
  ?serial:serial ->
  ?sender:string ->
  ?destination:string ->
  typ:'a ->
  unit -> 'a t

val method_call :
  ?flags:flags ->
  ?serial:serial ->
  ?sender:string ->
  ?destination:string ->
  path:path ->
  ?interface:interface ->
  member:member ->
  unit -> method_call

val method_return :
  ?flags:flags ->
  ?serial:serial ->
  ?sender:string ->
  ?destination:string ->
  reply_serial:serial ->
  unit -> method_return

val error :
  ?flags:flags ->
  ?serial:serial ->
  ?sender:string ->
  ?destination:string ->
  reply_serial:serial ->
  error_name:error_name ->
  unit -> error

val signal :
  ?flags:flags ->
  ?serial:serial ->
  ?sender:string ->
  ?destination:string ->
  path:path ->
  interface:interface ->
  member:member ->
  unit -> signal