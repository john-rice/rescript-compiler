(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)


 



let get_files ext dir = 
  Ext_array.filter_map (Sys.readdir dir)
    (fun  x ->
       if Ext_string.ends_with x  ext 
       then Some (Filename.concat dir x) else None )
  |> Array.to_list

(** the cache should be readable and also update *)

let from_cmj (files : string list) (output_file : string) = 
  let cmp = Ext_filename.module_name in     
  let files = List.sort (fun filea fileb  ->
      Ext_string_array.cmp (cmp filea) (cmp fileb)) files in 
  let keys = Ext_list.map files (fun x -> "\"" ^cmp x ^ "\"") in 
  let v = open_out_bin output_file in
  Ext_pervasives.finally v ~clean:close_out (fun f ->   
      output_string f {|
  let i s = lazy (Marshal.from_string s 0)     
  |};
      output_string f 
        (Printf.sprintf {|let module_sets = [|
%s
  |]|}
           (String.concat ";\n" keys)
        ) ;
      output_string f "\n";
      output_string f 
        (Printf.sprintf {|let module_sets_cmj : Js_cmj_format.t Lazy.t array = [|
%s
|] 
|} (String.concat ";\n" (Ext_list.map files (fun file -> 
            Printf.sprintf "i %S"
              (let content = Ext_io.load_file file in 
                String.sub content Ext_cmj_magic.header_length (String.length content - Ext_cmj_magic.header_length)
              )))));
              output_string f "\n";
              output_string f {|
              let query_by_name s =
                match Ext_string_array.find_sorted  
                  module_sets  s with 
                | None -> None
                | Some i -> 
                  Some (Lazy.force module_sets_cmj.(i))              
              |}

    ) 




let from_cmi (files : string list) (output_file : string) = 
  let cmp = Ext_filename.module_name in   
  let files = List.sort (fun filea fileb  ->
      Ext_string_array.cmp (cmp filea) (cmp fileb)) files in 
  let keys = Ext_list.map files (fun x -> "\"" ^ cmp x ^ "\"") in       
  let v = open_out_bin output_file in
  Ext_pervasives.finally v ~clean:close_out (fun f ->         
      output_string f {|
let i s = lazy (Marshal.from_string s 0)     
|};
      output_string f 
        (Printf.sprintf {|let module_sets = [|
%s
        |]|}
           (String.concat ";\n" keys)
        ) ;
      output_string f "\n";
      output_string f 
        (Printf.sprintf {|let module_sets_cmi : Cmi_format.cmi_infos Lazy.t array = [|
      %s
      |] 
      |} (String.concat ";\n" (Ext_list.map files (fun file -> 
            Printf.sprintf "i %S"
              (let content = (Cmi_format.read_cmi file) in 
               Marshal.to_string content []
               (* let header_len = (String.length Config.cmi_magic_number) in 
                  String.sub content header_len (String.length content - header_len) *)
              )))
          )
        )
    )
      ;;

let stdlib = "stdlib-406"
let (//) = Filename.concat 
let (|~) = Ext_string.contain_substring

let () = 
  let cmj_files = 
    ( 
       "runtime" // "js.cmj" ::
      get_files Literals.suffix_cmj stdlib @             
      get_files Literals.suffix_cmj "others") in 
  from_cmj cmj_files
    (Filename.concat "core" "builtin_cmj_datasets.ml");
  let cmi_files = 
    "runtime" // "js.cmi" ::       
    (get_files Literals.suffix_cmi stdlib @
    get_files Literals.suffix_cmi "others" )
    |> List.filter (fun x -> 
       x|~ "js_internalOO" ||
       x|~  "camlinternal" ||
       not (x |~ "internal"))
  in     
  from_cmi cmi_files
    (Filename.concat "core" "builtin_cmi_datasets.ml")

