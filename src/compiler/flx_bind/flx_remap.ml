open Flx_types
open Flx_btype
open Flx_bexpr
open Flx_bexe
open Flx_bparameter
open Flx_bbdcl

(** Remaps a bound index by adding an offset to it. *)
let remap_bid offset bid = bid + offset

(** Remaps bound types by adding an offset to the bound index. *)
let rec remap_btype offset btype =
  Flx_btype.map
    ~fi:(remap_bid offset)
    ~ft:(remap_btype offset)
    btype


(** Remap bound interfaces by adding an offset to the bound index. *)
let remap_biface offset biface =
  match biface with
  | BIFACE_export_fun (sr, bid, name) ->
      BIFACE_export_fun (sr, remap_bid offset bid, name)

  | BIFACE_export_python_fun (sr, bid, name) ->
      BIFACE_export_python_fun (sr, remap_bid offset bid, name)

  | BIFACE_export_type (sr, btype, name) ->
      BIFACE_export_type (sr, remap_btype offset btype, name)


(** Remap bound types by adding an offset to the bound index. *)
let rec remap_tbexpr offset bexpr =
  Flx_bexpr.map
    ~fi:(remap_bid offset)
    ~ft:(remap_btype offset)
    ~fe:(remap_tbexpr offset)
    bexpr


(** Remap bound exes by adding an offset to the bound index. *)
let remap_bexe offset bexe =
  Flx_bexe.map
    ~fi:(remap_bid offset)
    ~ft:(remap_btype offset)
    ~fe:(remap_tbexpr offset)
    bexe


(** Remaps bound declarations by adding an offset to the bound index. *)
let remap_bbdcl offset bbdcl =
  let remap_bid = remap_bid offset in
  let remap_btype = remap_btype offset in
  let remap_tbexpr = remap_tbexpr offset in
  let remap_bexe = remap_bexe offset in
  let remap_bvs = List.map (fun (n, i) -> n, remap_bid i) in
  let remap_bparameter bpar =
    { bpar with
      pindex = remap_bid bpar.pindex;
      ptyp = remap_btype bpar.ptyp }
  in
  let remap_bparams (bparameters, e) =
    let e = match e with None -> None | Some t -> Some (remap_tbexpr t) in
    (List.map remap_bparameter bparameters), e
  in
  let remap_breqs breqs =
    List.map (fun (i, ts) -> remap_bid i, List.map remap_btype ts) breqs
  in
  match bbdcl with
  | BBDCL_module ->
      bbdcl_module ()

  | BBDCL_function (props, vs, ps, res, es) ->
      let vs = remap_bvs vs in
      let ps = remap_bparams ps in
      let res = remap_btype res in
      let es = List.map remap_bexe es in
      bbdcl_function (props, vs, ps, res, es)

  | BBDCL_procedure (props, vs, ps, es) ->
      let vs = remap_bvs vs in
      let ps = remap_bparams ps in
      let es = List.map remap_bexe es in
      bbdcl_procedure (props, vs, ps, es)

  | BBDCL_val (vs, ty) ->
      bbdcl_val (remap_bvs vs, remap_btype ty)

  | BBDCL_var (vs, ty) ->
      bbdcl_var (remap_bvs vs, remap_btype ty)

  | BBDCL_ref (vs, ty) ->
      bbdcl_ref (remap_bvs vs, remap_btype ty)

  | BBDCL_tmp (vs, ty) ->
      bbdcl_tmp (remap_bvs vs, remap_btype ty)

  | BBDCL_newtype (vs, ty) ->
      bbdcl_newtype (remap_bvs vs, remap_btype ty)

  | BBDCL_abs (vs, quals, code, reqs) ->
      let vs = remap_bvs vs in
      let quals =
        List.map begin function
          | `Bound_needs_shape t -> `Bound_needs_shape (remap_btype t)
          | qual -> qual
        end quals
      in
      let reqs = remap_breqs reqs in
      bbdcl_abs (vs, quals, code, reqs)

  | BBDCL_const (props, vs, ty, code, reqs) ->
      let vs = remap_bvs vs in
      let ty = remap_btype ty in
      let reqs = remap_breqs reqs in
      bbdcl_const (props, vs, ty, code, reqs)

  | BBDCL_fun (props, vs, ps, rt, code, reqs, prec) ->
      let vs = remap_bvs vs in
      let ps = List.map remap_btype ps in
      let rt = remap_btype rt in
      let reqs = remap_breqs reqs in
      bbdcl_fun (props, vs, ps, rt, code, reqs, prec)

  | BBDCL_callback (props, vs, ps_cf, ps_c, k, rt, reqs, prec) ->
      let vs = remap_bvs vs in
      let ps_cf = List.map remap_btype ps_cf in
      let ps_c = List.map remap_btype ps_c in
      let rt = remap_btype rt in
      let reqs = remap_breqs reqs in
      bbdcl_callback (props, vs, ps_cf, ps_c, k, rt, reqs, prec)

  | BBDCL_proc (props, vs, ps, code, reqs) ->
      let vs = remap_bvs vs in
      let ps = List.map remap_btype ps in
      let reqs = remap_breqs reqs in
      bbdcl_proc (props, vs, ps, code, reqs)

  | BBDCL_insert (vs, code, ikind, reqs) ->
      let vs = remap_bvs vs in
      let reqs = remap_breqs reqs in
      bbdcl_insert (vs, code, ikind, reqs)

  | BBDCL_union (vs, cs) ->
      let vs = remap_bvs vs in
      let cs = List.map (fun (n,v,t) -> n,v,remap_btype t) cs in
      bbdcl_union (vs, cs)

  | BBDCL_struct (vs, cs) ->
      let vs = remap_bvs vs in
      let cs = List.map (fun (n,t) -> n,remap_btype t) cs in
      bbdcl_struct (vs, cs)

  | BBDCL_cstruct (vs, cs) ->
      let vs = remap_bvs vs in
      let cs = List.map (fun (n,t) -> n,remap_btype t) cs in
      bbdcl_cstruct (vs, cs)

  | BBDCL_typeclass (props, vs) ->
      bbdcl_typeclass (props, remap_bvs vs)

  | BBDCL_instance (props, vs, cons, bid, ts) ->
      let vs = remap_bvs vs in
      let cons = remap_btype cons in
      let bid = remap_bid bid in
      let ts = List.map remap_btype ts in
      bbdcl_instance (props, vs, cons, bid, ts)

  | BBDCL_nonconst_ctor (vs, uidx, ut, ctor_idx, ctor_argt, evs, etraint) ->
      let vs = remap_bvs vs in
      let uidx = remap_bid uidx in
      let ut = remap_btype ut in
      let ctor_argt = remap_btype ctor_argt in
      let evs = remap_bvs evs in
      let etraint = remap_btype etraint in
      bbdcl_nonconst_ctor (vs, uidx, ut, ctor_idx, ctor_argt, evs, etraint)

  | BBDCL_axiom -> bbdcl_axiom ()
  | BBDCL_lemma -> bbdcl_lemma ()
  | BBDCL_reduce -> bbdcl_reduce ()


(** Remap symbols from an old bound symbol table to a new one by offsetting the
 * bound index by a constant amount. *)
let remap offset in_bsym_table out_bsym_table =
  Flx_bsym_table.iter begin fun bid bsym ->
    let bid = remap_bid offset bid in
    let parent =
      match bsym.Flx_bsym.parent with
      | None -> None
      | Some parent -> Some (remap_bid offset bid)
    in
    let bbdcl = remap_bbdcl offset bsym.Flx_bsym.bbdcl in
    Flx_bsym_table.add out_bsym_table bid { bsym with Flx_bsym.bbdcl=bbdcl }
  end in_bsym_table
