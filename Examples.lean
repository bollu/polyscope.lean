/-
Copyright (c) 2022 Siddharth Bhat. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Siddharth Bhat
-/
import Polyscope
import Polyscope.Mesh
import ProofWidgets.Component.HtmlDisplay
open Lean ProofWidgets
open scoped ProofWidgets.Jsx

/-! Ported from Lean 3 code by Oliver Nash:
https://gist.github.com/ocfnash/fb61a17d0f1598edcc752999f17b70c6 -/

def List.product : List α → List β → List (α × β)
  | [], _     => []
  | a::as, bs => bs.map ((a, ·)) ++ as.product bs

def Matrix (n m α : Type) := n → m → α

namespace Matrix

open ProofWidgets
open scoped Jsx Json

variable {n : Nat} (A : Matrix (Fin n) (Fin n) Int)

def nat_index (i j : Nat) : Int :=
  if h : i < n ∧ j < n then A ⟨i, h.1⟩ ⟨j, h.2⟩ else 999

/-- TODO Delete me once `get_node_pos` smart enough to infer layout from values in `A`. -/
def get_node_pos_E : Nat → Nat × Nat
  | 0     => ⟨0, 0⟩
  | 1     => ⟨2, 1⟩
  | (i+1) => ⟨i, 0⟩

/-- TODO Use `A` to infer sensible layout. -/
def get_node_pos (n : Nat) : Nat → Nat × Nat := if n < 6 then ((·, 0)) else get_node_pos_E

def get_node_cx (n i : Nat) : Int := 20 + (get_node_pos n i).1 * 40

def get_node_cy (n i : Nat) : Int := 20 + (get_node_pos n i).2 * 40

def get_node_html (n i : Nat) : THtml :=
  <circle
    cx={toString <| get_node_cx n i}
    cy={toString <| get_node_cy n i}
    r="10"
    fill="white"
    stroke="black" />

/-- TODO
 * Error if `j ≤ i`
 * Error if `(A i j, A j i) ∉ [((0 : Int), (0 : Int)), (-1, -1), (-1, -2), (-2, -1), (-1, -3), (-3, -1)]`
 * Render `(A i j) * (A j i)` edges
 * Render arrow on double or triple edge with direction decided by `A i j < A j i` -/
def get_edge_html : Nat × Nat → List THtml
  | (i, j) => if A.nat_index i j = 0 then [] else
  [<line
     x1={toString <| get_node_cx n i}
     y1={toString <| get_node_cy n i}
     x2={toString <| get_node_cx n j}
     y2={toString <| get_node_cy n j}
     fill="black"
     stroke="black" />]

def get_nodes_html (n : Nat) : List THtml :=
  (List.range n).map (get_node_html n)

def get_edges_html : List THtml := Id.run do
  let mut out := []
  for j in [:n] do
    for i in [:j] do
      out := A.get_edge_html (i, j) ++ out
  return out

def toTHtml (M : Matrix (Fin n) (Fin n) Int) : THtml :=
  <div style={json% { height: "100px", width: "300px", background: "grey" }}>
    {THtml.element "svg" #[] (M.get_edges_html ++ Matrix.get_nodes_html n).toArray}
  </div>

end Matrix

def cartanMatrix.E₈ : Matrix (Fin 8) (Fin 8) Int :=
  fun i j =>
    [[ 2,  0, -1,  0,  0,  0,  0,  0],
     [ 0,  2,  0, -1,  0,  0,  0,  0],
     [-1,  0,  2, -1,  0,  0,  0,  0],
     [ 0, -1, -1,  2, -1,  0,  0,  0],
     [ 0,  0,  0, -1,  2, -1,  0,  0],
     [ 0,  0,  0,  0, -1,  2, -1,  0],
     [ 0,  0,  0,  0,  0, -1,  2, -1],
     [ 0,  0,  0,  0,  0,  0, -1,  2]].get! i |>.get! j

-- Place your cursor here
#html cartanMatrix.E₈.toTHtml


structure RubiksProps where
  seq : Array String := #[]
  deriving ToJson, FromJson, Inhabited

@[widget_module]
def Rubiks : Component RubiksProps where
  javascript := include_str "build" / "js" / "rubiks.js"

def eg := #["L", "L", "D⁻¹", "U⁻¹", "L", "D", "D", "L", "U⁻¹", "R", "D", "F", "F", "D"]

#html <Rubiks seq={eg} />

/-- Actually do the IO. This incurs an `unsafe` -/
unsafe def unsafePerformIO [Inhabited α] (io: IO α): α :=
  match unsafeIO io with
  | Except.ok a    =>  a
  | Except.error _ => panic! "expected io computation to never fail"

/-- Circumvent the `unsafe` by citing an `implementedBy` instance. -/
@[implemented_by unsafePerformIO]
def performIO [Inhabited α] (io: IO α): α := Inhabited.default

def egRandVertices : Array Float :=
  (randVertices mkStdGen (nvertices := 500)).fst

def egRandFaces : Array Nat :=
  (randTriFaces mkStdGen (nvertices := 500) (nfaces := 500)).fst

/- A random mesh. -/
#html <Mesh vertices={egRandVertices} faces={egRandFaces} />

/-- The stanford bunny, loaded from a file. -/
def _sphere : MeshProps := performIO <| MeshProps.fromOFFFile "./data/sphere_s3.off"
#html <Mesh vertices={_sphere.vertices} faces={_sphere.faces} />


/-- The stanford bunny, loaded from a file. -/
def _bunny : MeshProps := performIO <| MeshProps.fromOFFFile "./data/bunny.off"
#html <Mesh vertices={_bunny.vertices} faces={_bunny.faces} />

def main : IO Unit := do
  let _sphere ← MeshProps.fromOFFFile "./data/sphere_s3.off"
  let _bunny ← MeshProps.fromOFFFile "./data/bunny.off"
  IO.println s!"loaded all meshes."
