(* This is a single-line comment. *)

type t = Int of int | Str of string

let some_value = [Int 42; Str "Hello, world"]

let rec print_mixed lst =
  match lst with
  |[] -> ()
  |hd :: rst ->
    (match hd with
     |Int a -> print_int(a)
     |Str s -> print_string(s));
    print_newline(); print_mixed rst
;;

print_mixed some_value
