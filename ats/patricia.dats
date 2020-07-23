#include "share/atspre_staload.hats"
#include "prelude/fixity.ats"
staload UN = "prelude/SATS/unsafe.sats"

typedef BB = [r:nat|0<=r && r < 64] int(r)

datatype patricia (a:t@ype)
= B of (uint, BB, patricia a, patricia a) | L of (uint, a) | E

fun{a:t@ype} singleton (k : uint, v : a) : patricia a = L (k, v)

(* from scheme : (logbit0 b (logor k (- (ash 1 b) 1)))
   set bits clear bit, setting bits below it *)
fn mask (bit:BB, key:uint) : uint = let
 val _2m = g0int2uint (1 << bit) in (lnot _2m) land (key lor (_2m - 1U)) end

(* ((k p b) (= (logbit0 b (logor k (- (ash 1 b) 1)))  p)) *)
fn match_prefix (bit:BB, pre:uint, key:uint) : bool = pre = mask (bit, key)

fn{a:t@ype} match_tree_prefix (tree:patricia a, key:uint) : bool = 
case tree of | B (p,b,_,_) => match_prefix (b,p,key) | _ => false

fn is_bit_set (key:uint, bit:BB) : bool = g0uint_eq (1U, 1U land (key >> bit))

(* cool *)
(* branching-bit   (- (bitwise-length (logxor p1 p2)) 1) *)
fn branch_bit{n,m:nat|n != m} (p1:uint(n), p2:uint(m)) : BB =
$UN.cast(63 - $extfcall(int, "__builtin_clzl", p1 lxor p2))

fn{a:t@ype} join_tree {n,m:nat|n != m}
(px:uint(n), tx:patricia a, py:uint(m), ty:patricia a) : patricia a = 
let val bit = branch_bit(px,py) in
if is_bit_set (px,bit) then B(px,bit,tx,ty) else B (py, bit, tx, ty) end

fn{a:t@ype} make_tree 
(p:uint, b:BB, tx:patricia a, ty:patricia a) : patricia a =
case tx of | E() => ty | _ => case ty of | E() => tx | _ => B (p,b,tx,ty)

fn {a:t@ype} lookup (key:uint, tree:patricia a) : Option a = let
  fun lp (tree : patricia a) = case tree of
    | E() => None
    | L(k,v) => if k = key then Some v else None
    | B(p,b,L,R) when match_prefix (b,p,key) => if key <= p then lp L else lp R
    | _ => None
in lp tree end

fn {a:t@ype} insert (k:uint, v: a, T:patricia a) : patricia a = let
  fun lp (T : patricia a) = case- T of
  | E => k \L v
  | S as L (k_,v_) => if k = k_ then L(k,v) else join_tree (k,T,k_,S)
in lp T end



(* int __builtin_clz (unsigned int x) *)
val () = println!("7   = ", mask(3,10U))
val () = println!("23  = ", mask(3,20U))
val () = println!("103 = ", mask(3,100U))
val () = println!("95  = ", mask(5,100U))
val () = println!("1 = ", is_bit_set(5U,2))
val () = println!("0 = ", is_bit_set(5U,1))
val () = println!("1 = ", is_bit_set(5U,0))
val () = println!("4 = ", branch_bit(5U,20U))
val () = println!("3 = ", branch_bit(10U,5U))

implement main0 () = ()
