(*
 * uDisks_adapter.ml
 * -----------------
 * Copyright : (c) 2010, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of obus, an ocaml implementation of D-Bus.
 *)

include OBus_proxy.Private

open UDisks_interfaces.Org_freedesktop_UDisks_Adapter

let changed proxy =
  OBus_signal.connect s_Changed proxy

let native_path proxy =
  OBus_property.make p_NativePath proxy

let vendor proxy =
  OBus_property.make p_Vendor proxy

let model proxy =
  OBus_property.make p_Model proxy

let driver proxy =
  OBus_property.make p_Driver proxy

let num_ports proxy =
  OBus_property.map_r
    (fun x -> Int32.to_int x)
    (OBus_property.make p_NumPorts proxy)

let fabric proxy =
  OBus_property.make p_Fabric proxy

type properties = {
  fabric : string;
  num_ports : int;
  driver : string;
  model : string;
  vendor : string;
  native_path : string;
}

let properties proxy =
  OBus_property.map_r_with_context
    (fun context properties ->
       let find f = OBus_property.find (f proxy) context properties in
       {
         fabric = find fabric;
         num_ports = find num_ports;
         driver = find driver;
         model = find model;
         vendor = find vendor;
         native_path = find native_path;
       })
    (OBus_property.make_group proxy interface)
