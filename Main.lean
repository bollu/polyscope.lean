-- Widgets for rendering meshes and shaders.
import Mesh
import ProofWidgets.Component.HtmlDisplay
import Lean
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

abbrev Vec3 : Type := Array Float
abbrev Vertices : Type := Array Vec3
abbrev Faces : Type := Array Nat


structure MeshProps where
  vertices : Array Float
  faces : Faces
deriving Server.RpcEncodable, Inhabited

@[widget_module]
def Mesh : Component MeshProps where
  javascript := include_str "build" / "js" / "mesh.js"



def randFloat01 [G : RandomGen γ] (gen : γ) : Float × γ := Id.run do do
  let (val, gen) := G.next gen
  let (lo, hi) := G.range gen
  return ((Float.ofNat <| val - lo) / (Float.ofNat <| hi - lo), gen)

def nvertices : Nat:= 500
def nfaces : Nat:= 100

def verticesGen [RandomGen γ] (gen : γ): (Array Float) × γ := Id.run do
  let mut gen := gen
  let mut out : Array Float := #[]
  for _ in List.range nvertices do
    let (val, gen') := randFloat01 gen
    gen := gen'
    out := out.push <| (val - 0.5) * 10
  return (out, gen)

def vertices : Array Float := (verticesGen mkStdGen).fst

def facesGen [RandomGen γ] (gen : γ) : (Array Nat) × γ := Id.run do
  let mut out : Array Nat := #[]
  let mut gen := gen
  for _ in List.range nfaces do
    let (v1, gen') := randNat gen 0 (nvertices-1); gen := gen'
    let (v2, gen') := randNat gen 0 (nvertices-1); gen := gen'
    let (v3, gen') := randNat gen 0 (nvertices-1); gen := gen'
    out := out.push v1
    out := out.push v2
    out := out.push v3
  return (out, gen)

def faces : Array Nat := (facesGen mkStdGen).fst

#html <Mesh vertices={vertices} faces={faces} />


-- | Actually do the IO. This incurs an `unsafe`.
unsafe def unsafePerformIO [Inhabited α] (io: IO α): α :=
  match unsafeIO io with
  | Except.ok a    =>  a
  | Except.error _ => panic! "expected io computation to never fail"

-- | Circumvent the `unsafe` by citing an `implementedBy` instance.
@[implemented_by unsafePerformIO]
def performIO [Inhabited α] (io: IO α): α := Inhabited.default


def loadMeshFromOffData [Monad m] [MonadExceptOf String m] (lines : Array String) : m MeshProps := do
  let mut verts : Array Float := #[]
  let mut faces : Array Nat := #[]
  let mut i := 0
  if lines[i]!.trim != "OFF"
  then throw s!"expected 'OFF' on line {i+1}. but found '{lines[i]!}' which is not .OFF"
  i := i + 1

  let [n_vertices, n_faces, _n_edges] := lines[i]!.trim.splitOn " "
    | throw s!"expected number of vertices, faces, edges information on line {i+1}, but found '{lines[i]!}'"
  i := i + 1

  let .some n_vertices := n_vertices.toNat?
    | throw s! "unable to parse num vertices {n_vertices}"

  let .some n_faces := n_faces.toNat?
    | throw s! "unable to parse num faces {n_faces}"

  for _ in List.range n_vertices do
    let coords_raw := lines[i]!.trim.splitOn " "
    let mut v : Array Float := #[]
    for coord in coords_raw do
      let .ok coord := Lean.Json.Parser.num |>.run coord
        | throw s!"unable to parse vertex coordinate {coord} on line {i+1}"
        v := v.push coord.toFloat
    verts := verts.append v
    i := i + 1

  for _ in List.range n_faces do
    let face_indexes_raw := lines[i]!.trim.splitOn " "
    let mut f : Array Nat := #[]
    for ix in face_indexes_raw.drop 1 do
      let .some ix := ix.toNat?
        | throw s!"unable to parse face index {ix} on line {i+1}"
        f := f.push ix
    faces := faces.append f
    i := i + 1

  return {vertices := verts, faces := faces}

open System in
def loadMeshFromOffFile (p : System.FilePath) : IO MeshProps := do
  let out : Except String MeshProps := loadMeshFromOffData (← IO.FS.lines p)
  match out with
  | .ok out => return out
  | .error err => throw <| .userError err


def sphere : MeshProps := performIO <| loadMeshFromOffFile "./data/sphere_s3.off"
#html <Mesh vertices={sphere.vertices} faces={sphere.faces} />


def bunny : MeshProps := performIO <| loadMeshFromOffFile "./data/bunny.off"
#html <Mesh vertices={bunny.vertices} faces={bunny.faces} />

def main : IO Unit := do
  let sphere ← loadMeshFromOffFile "./data/sphere_s3.off"
  let bunny ← loadMeshFromOffFile "./data/bunny.off"
  IO.println s!"Hello, {hello}!"
