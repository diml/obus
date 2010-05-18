(*
 * nm_ip6_config.ml
 * ----------------
 * Copyright : (c) 2010, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *)

include OBus_proxy.Private

open Nm_interfaces.Org_freedesktop_NetworkManager_IP6Config

let addresses proxy =
  OBus_property.map_r
    (fun x -> List.map (fun (x1, x2) -> (x1, Int32.to_int x2)) x)
    (OBus_property.make p_Addresses proxy)

let nameservers proxy =
  OBus_property.make p_Nameservers proxy

let domains proxy =
  OBus_property.make p_Domains proxy

let routes proxy =
  OBus_property.map_r
    (fun x -> List.map (fun (x1, x2, x3, x4) -> (x1, Int32.to_int x2, x3, Int32.to_int x4)) x)
    (OBus_property.make p_Routes proxy)

type properties = {
  addresses : (string * int) list;
  nameservers : string list;
  domains : string list;
  routes : (string * int * string * int) list;
}

let properties proxy =
  OBus_property.map_r_with_context
    (fun context properties ->
       let find f = OBus_property.find (f proxy) context properties in
       {
         addresses = find addresses;
         nameservers = find nameservers;
         domains = find domains;
         routes = find routes;
       })
    (OBus_property.make_group proxy interface)
