(*
 * oBus_path.ml
 * ------------
 * Copyright : (c) 2008, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of obus, an ocaml implemtation of dbus.
 *)

open Printf
open String
open OBus_string

type element = string
type t = element list

exception Invalid_path of string * string
exception Invalid_element of string * string

let is_valid_char ch =
  (ch >= 'A' && ch <= 'Z') ||
    (ch >= 'a' && ch <= 'z') ||
    (ch >= '0' && ch <= '9') ||
    ch = '_'

let validate str =
  let fail i msg = Some{ typ = "path"; str = str; ofs = i; msg = msg }
  and len = length str in

  let rec aux_element_start i =
    if i = len then
      fail (i - 1) "trailing '/'"
    else if is_valid_char (unsafe_get str i) then
      aux_element (i + 1)
    else if unsafe_get str i = '/' then
      fail i "empty element"
    else
      fail i "invalid char"

  and aux_element i =
    if i = len then
      None
    else
      let ch = unsafe_get str i in
      if ch = '/' then
        aux_element_start (i + 1)
      else if is_valid_char ch then
        aux_element (i + 1)
      else
        fail i "invalid char"
  in

  if len = 0 then
    fail (-1) "empty path"
  else if unsafe_get str 0 = '/' then
    if len = 1 then None else aux_element_start 1
  else
    fail 0 "must start with '/'"

let validate_element = function
  | "" ->
      Some{ typ = "path element"; str = ""; ofs = -1; msg = "empty element" }
  | str ->
      let len = length str in
      let rec aux i =
        if i = len then
          None
        else if is_valid_char (unsafe_get str i) then
          aux (i + 1)
        else
          Some{ typ = "path element"; str = ""; ofs = i; msg = "invalid character" }
      in
      aux 0

let empty = []

let to_string = function
  | [] -> "/"
  | path ->
      let str = create (List.fold_left (fun len elt -> len + length elt + 1) 0 path) in
      ignore
        (List.fold_left
           (fun pos elt ->
              match validate_element elt with
                | None ->
                    unsafe_set str pos '/';
                    let len = length elt in
                    unsafe_blit elt 0 str (pos + 1) len;
                    pos + 1 + len
                | Some error ->
                    raise (Invalid_string error))
           0 path);
      str

let of_string str =
  match validate str with
    | Some error ->
        raise (OBus_string.Invalid_string error)
    | None ->
        let rec aux acc j =
          if j <= 0 then
            acc
          else
            let i = rindex_from str j '/' in
            let len = j - i in
            let elt = create len in
            unsafe_blit str (i + 1) elt 0 len;
            aux (elt :: acc) (i - 1)
        in
        aux [] (length str - 1)

let escape s =
  let len = length s in
  let r = create (len * 2) in
  for i = 0 to len - 1 do
    let j = i * 2 in
    r.[j] <- char_of_int (int_of_char s.[i] land 15 + int_of_char 'a');
    r.[j] <- char_of_int (int_of_char s.[i + 1] lsr 4 + int_of_char 'a')
  done;
  r

let unescape s =
  let len = length s / 2 in
  let r = create len in
  for i = 0 to len - 1 do
    let j = i * 2 in
    r.[i] <- char_of_int ((int_of_char s.[j] - int_of_char 'a') lor
                            ((int_of_char s.[j + 1] - int_of_char 'a') lsl 4))
  done;
  r

let rec after prefix path = match prefix, path with
  | [], p -> Some p
  | e1 :: p1, e2 :: p2 when e1 = e2 -> after p1 p2
  | _ -> None
