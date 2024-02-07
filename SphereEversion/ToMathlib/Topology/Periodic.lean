import Mathlib.Algebra.Periodic
import Mathlib.Analysis.NormedSpace.Basic
import SphereEversion.ToMathlib.Topology.Separation

/-!

# Boundedness property of periodic function

The main purpose of that file it to prove
```
lemma Continuous.bounded_of_onePeriodic_of_isCompact {f : X → ℝ → E} (cont : Continuous ↿f)
  (hper : ∀ x, OnePeriodic (f x)) {K : set X} (hK : IsCompact K) (hfK : ∀ x ∉ K, f x = 0) :
  ∃ C, ∀ x t, ‖f x t‖ ≤ C
```

This is done by introducing the quotient 𝕊₁ = ℝ/ℤ as a compact topological space. Patrick is not sure
this is the optimal version.

In the first part, generalize many lemmas to any period and add to algebra/periodic.lean?

-/


noncomputable section

open Set Function Filter TopologicalSpace Int

open scoped Topology

section OnePeriodic

variable {α : Type _}

/-- The integers as an additive subgroup of the reals. -/
def ℤSubℝ : AddSubgroup ℝ :=
  AddMonoidHom.range (Int.castAddHom ℝ)

/-- The equivalence relation on `ℝ` corresponding to its partition as cosets of `ℤ`. -/
def transOne : Setoid ℝ :=
  QuotientAddGroup.leftRel ℤSubℝ

/-- The proposition that a function on `ℝ` is periodic with period `1`. -/
def OnePeriodic (f : ℝ → α) : Prop :=
  Periodic f 1

theorem OnePeriodic.add_nat {f : ℝ → α} (h : OnePeriodic f) (k : ℕ) (x : ℝ) : f (x + k) = f x := by
  simpa using h.nat_mul k x

theorem OnePeriodic.add_int {f : ℝ → α} (h : OnePeriodic f) (k : ℤ) (x : ℝ) : f (x + k) = f x := by
  simpa using h.int_mul k x

/-- The circle `𝕊₁ := ℝ/ℤ`.

TODO [Yury]: use `AddCircle`. -/
def 𝕊₁ :=
  Quotient transOne
deriving TopologicalSpace, Inhabited

theorem transOne_rel_iff {a b : ℝ} : transOne.Rel a b ↔ ∃ k : ℤ, b = a + k := by
  refine QuotientAddGroup.leftRel_apply.trans ?_
  refine exists_congr fun k ↦ ?_
  rw [coe_castAddHom, eq_neg_add_iff_add_eq, eq_comm]

section

attribute [local instance] transOne

/-- The quotient map from the reals to the circle `ℝ ⧸ ℤ`. -/
def proj𝕊₁ : ℝ → 𝕊₁ :=
  Quotient.mk'

@[simp]
theorem proj𝕊₁_add_int (t : ℝ) (k : ℤ) : proj𝕊₁ (t + k) = proj𝕊₁ t := by
  symm
  apply Quotient.sound
  exact transOne_rel_iff.mpr ⟨k, rfl⟩

/-- The unique representative in the half-open interval `[0, 1)` for each coset of `ℤ` in `ℝ`,
regarded as a map from the circle `𝕊₁ → ℝ`. -/
def 𝕊₁.repr (x : 𝕊₁) : ℝ :=
  let t := Quotient.out x
  fract t

theorem 𝕊₁.repr_mem (x : 𝕊₁) : x.repr ∈ (Ico 0 1 : Set ℝ) :=
  ⟨fract_nonneg _, fract_lt_one _⟩

theorem 𝕊₁.proj_repr (x : 𝕊₁) : proj𝕊₁ x.repr = x := by
  symm
  conv_lhs => rw [← Quotient.out_eq x]
  rw [← fract_add_floor (Quotient.out x)]
  apply proj𝕊₁_add_int

theorem image_proj𝕊₁_Ico : proj𝕊₁ '' Ico 0 1 = univ := by
  rw [eq_univ_iff_forall]
  intro x
  use x.repr, x.repr_mem, x.proj_repr

theorem image_proj𝕊₁_Icc : proj𝕊₁ '' Icc 0 1 = univ :=
  eq_univ_of_subset (image_subset proj𝕊₁ Ico_subset_Icc_self) image_proj𝕊₁_Ico

@[continuity]
theorem continuous_proj𝕊₁ : Continuous proj𝕊₁ :=
  continuous_quotient_mk'

theorem isOpenMap_proj𝕊₁ : IsOpenMap proj𝕊₁ :=
  QuotientAddGroup.isOpenMap_coe ℤSubℝ

theorem quotientMap_id_proj𝕊₁ {X : Type _} [TopologicalSpace X] :
    QuotientMap fun p : X × ℝ ↦ (p.1, proj𝕊₁ p.2) :=
  (IsOpenMap.id.prod isOpenMap_proj𝕊₁).to_quotientMap (continuous_id.prod_map continuous_proj𝕊₁)
    (surjective_id.Prod_map Quotient.exists_rep)

/-- A one-periodic function on `ℝ` descends to a function on the circle `ℝ ⧸ ℤ`. -/
def OnePeriodic.lift {f : ℝ → α} (h : OnePeriodic f) : 𝕊₁ → α :=
  Quotient.lift f (by intro a b hab; rcases transOne_rel_iff.mp hab with ⟨k, rfl⟩; rw [h.add_int])

end

local notation "π" => proj𝕊₁

instance : CompactSpace 𝕊₁ :=
  ⟨by rw [← image_proj𝕊₁_Icc]; exact isCompact_Icc.image continuous_proj𝕊₁⟩

theorem isClosed_int : IsClosed (range ((↑) : ℤ → ℝ)) :=
  Int.closedEmbedding_coe_real.closed_range

instance : T2Space 𝕊₁ := by
  have πcont : Continuous π := continuous_quotient_mk'
  rw [t2Space_iff_of_continuous_surjective_open πcont Quotient.surjective_Quotient_mk''
      isOpenMap_proj𝕊₁]
  have : {q : ℝ × ℝ | π q.fst = π q.snd} = {q : ℝ × ℝ | ∃ k : ℤ, q.2 = q.1 + k}
  · ext ⟨a, b⟩
    exact Quotient.eq''.trans transOne_rel_iff
  have : {q : ℝ × ℝ | π q.fst = π q.snd} = (fun q : ℝ × ℝ ↦ q.2 - q.1) ⁻¹' (range <| ((↑) : ℤ → ℝ))
  · rw [this]
    ext ⟨a, b⟩
    refine exists_congr fun k ↦ ?_
    conv_rhs => rw [eq_comm, sub_eq_iff_eq_add']
  rw [this]
  exact IsClosed.preimage (continuous_snd.sub continuous_fst) isClosed_int

variable {X E : Type _} [TopologicalSpace X] [NormedAddCommGroup E]

theorem Continuous.bounded_on_compact_of_onePeriodic {f : X → ℝ → E} (cont : Continuous ↿f)
    (hper : ∀ x, OnePeriodic (f x)) {K : Set X} (hK : IsCompact K) :
    ∃ C, ∀ x ∈ K, ∀ t, ‖f x t‖ ≤ C := by
  let F : X × 𝕊₁ → E := fun p : X × 𝕊₁ ↦ (hper p.1).lift p.2
  have Fcont : Continuous F
  · have qm : QuotientMap fun p : X × ℝ ↦ (p.1, π p.2) := quotientMap_id_proj𝕊₁
    -- avoid weird elaboration issue
    have : ↿f = F ∘ fun p : X × ℝ ↦ (p.1, π p.2) := by ext p; rfl
    rwa [this, ← qm.continuous_iff] at cont
  obtain ⟨C, hC⟩ :=
    (hK.prod isCompact_univ).bddAbove_image (continuous_norm.comp Fcont).continuousOn
  exact ⟨C, fun x x_in t ↦ hC ⟨(x, π t), ⟨x_in, mem_univ _⟩, rfl⟩⟩

theorem Continuous.bounded_of_onePeriodic_of_compact {f : X → ℝ → E} (cont : Continuous ↿f)
    (hper : ∀ x, OnePeriodic (f x)) {K : Set X} (hK : IsCompact K)
    (hfK : ∀ x ∉ K, f x = 0) : ∃ C, ∀ x t, ‖f x t‖ ≤ C := by
  obtain ⟨C, hC⟩ := cont.bounded_on_compact_of_onePeriodic hper hK
  use max C 0
  intro x t
  by_cases hx : x ∈ K
  · exact le_max_of_le_left (hC x hx t)
  · simp [hfK, hx]

end OnePeriodic
