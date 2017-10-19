open Flx_types

let pub_table_dir counter (sym_table:Flx_sym_table.t) (invs,i,ts) : Flx_name_map.name_map_t =
  let invs = List.map (fun (i,n,_)->i,n) (fst invs) in
  let sym = Flx_sym_table.find sym_table i in
  match sym.Flx_sym.symdef with
  | SYMDEF_root _ 
  | SYMDEF_library 
  | SYMDEF_module ->
    let table = 
      if List.length ts = 0 
      then sym.Flx_sym.pubmap 
      else Flx_name_map.make_view_table counter sym.Flx_sym.pubmap (sym.Flx_sym.sr) invs ts 
    in
    table

  | SYMDEF_typeclass  ->
    let table = 
      if List.length ts = 0 
      then sym.Flx_sym.pubmap 
      else Flx_name_map.make_view_table counter sym.Flx_sym.pubmap (sym.Flx_sym.sr) invs ts 
    in
    (* a bit hacky .. add the type class specialisation view
       to its contents as an instance
    *)
    let inst = Flx_name_map.mkentry counter sym.Flx_sym.vs i in
    let inst = Flx_name_map.review_entry counter sym.Flx_sym.id sym.Flx_sym.sr invs ts inst in
    let inst_name = "_inst_" ^ sym.Flx_sym.id in

    (* add inst thing to table *)
    Hashtbl.add table inst_name (FunctionEntry [inst]);
    table

  | _ ->
      Flx_exceptions.clierrx "[flx_bind/flx_lookup.ml:6142: E228] " sym.Flx_sym.sr "[map_dir] Expected module"


