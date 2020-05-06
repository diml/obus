(*
 * nm_connection.ml
 * ----------------
 * Copyright : (c) 2010, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *)

open Lwt

let section = Lwt_log.Section.make "network-manager(connection)"

include OBus_proxy.Private

open Nm_interfaces.Org_freedesktop_NetworkManager_Connection_Active

type state = [ `Unknown | `Activating | `Activated ]

let service_name proxy =
  OBus_property.make ~monitor:Nm_monitor.monitor p_ServiceName proxy

let connection proxy =
  OBus_property.map_r_with_context
    (fun context x ->
      Nm_settings.Connection.of_proxy
        (OBus_proxy.make (OBus_context.sender context) x))
    (OBus_property.make ~monitor:Nm_monitor.monitor p_Connection proxy)

let specific_object proxy =
  OBus_property.map_r_with_context
    (fun context x -> OBus_proxy.make (OBus_context.sender context) x)
    (OBus_property.make ~monitor:Nm_monitor.monitor p_SpecificObject proxy)

let devices proxy =
  OBus_property.map_r_with_context
    (fun context paths ->
      List.map
        (fun path ->
          Nm_device.of_proxy
            (OBus_proxy.make (OBus_context.sender context) path))
        paths)
    (OBus_property.make ~monitor:Nm_monitor.monitor p_Devices proxy)

let state proxy =
  OBus_property.map_r
    (function
      | 0l -> `Unknown
      | 1l -> `Activating
      | 2l -> `Activated
      | st ->
          ignore
            (Lwt_log.warning_f ~section
               "Nm_connection.state: unknown state: %ld" st);
          `Unknown)
    (OBus_property.make ~monitor:Nm_monitor.monitor p_State proxy)

let default proxy =
  OBus_property.make ~monitor:Nm_monitor.monitor p_Default proxy

let vpn proxy = OBus_property.make ~monitor:Nm_monitor.monitor p_Vpn proxy

let properties_changed proxy = OBus_signal.make s_PropertiesChanged proxy

let properties proxy =
  OBus_property.group ~monitor:Nm_monitor.monitor proxy interface
