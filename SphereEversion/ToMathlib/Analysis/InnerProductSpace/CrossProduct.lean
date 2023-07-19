/-
Copyright (c) 2022 Heather Macbeth. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Heather Macbeth

! This file was ported from Lean 3 source module to_mathlib.analysis.inner_product_space.cross_product
-/
import Mathlib.Analysis.InnerProductSpace.Dual
import Mathlib.Analysis.InnerProductSpace.Orientation

/-! # The cross-product on an oriented real inner product space of dimension three -/


noncomputable section

open scoped RealInnerProductSpace

open FiniteDimensional

attribute [local instance] fact_finiteDimensional_of_finrank_eq_succ

variable (E : Type _) [NormedAddCommGroup E] [InnerProductSpace ℝ E]

/-- The identification of a finite-dimensional inner product space with its algebraic dual. -/
private def to_dual [FiniteDimensional ℝ E] : E ≃ₗ[ℝ] E →ₗ[ℝ] ℝ :=
  (InnerProductSpace.toDual ℝ E).toLinearEquiv ≪≫ₗ LinearMap.toContinuousLinearMap.symm

namespace Orientation

variable {E}
variable [Fact (finrank ℝ E = 3)] (ω : Orientation ℝ E (Fin 3))

/-- Linear map from `E` to `E →ₗ[ℝ] E` constructed from a 3-form `Ω` on `E` and an identification of
`E` with its dual.  Effectively, the Hodge star operation.  (Under appropriate hypotheses it turns
out that the image of this map is in `𝔰𝔬(E)`, the skew-symmetric operators, which can be identified
with `Λ²E`.) -/
def crossProduct : E →ₗ[ℝ] E →ₗ[ℝ] E := by
  let z : AlternatingMap ℝ E ℝ (Fin 0) ≃ₗ[ℝ] ℝ :=
    AlternatingMap.constLinearEquivOfIsEmpty.symm
  let y : AlternatingMap ℝ E ℝ (Fin 1) →ₗ[ℝ] E →ₗ[ℝ] ℝ :=
    LinearMap.llcomp ℝ E (AlternatingMap ℝ E ℝ (Fin 0)) ℝ z ∘ₗ AlternatingMap.curryLeftLinearMap
  let y' : AlternatingMap ℝ E ℝ (Fin 1) →ₗ[ℝ] E :=
    (LinearMap.llcomp ℝ (AlternatingMap ℝ E ℝ (Fin 1)) (E →ₗ[ℝ] ℝ) E (to_dual E).symm) y
  let u : AlternatingMap ℝ E ℝ (Fin 2) →ₗ[ℝ] E →ₗ[ℝ] E :=
    LinearMap.llcomp ℝ E (AlternatingMap ℝ E ℝ (Fin 1)) _ y' ∘ₗ AlternatingMap.curryLeftLinearMap
  exact u ∘ₗ AlternatingMap.curryLeftLinearMap (n := 2) ω.volumeForm

local infixl:100 "×₃" => ω.crossProduct

theorem crossProduct_apply_self (v : E) : v×₃v = 0 := by simp [crossProduct]

theorem inner_crossProduct_apply (u v w : E) : ⟪u×₃v, w⟫ = ω.volumeForm ![u, v, w] := by
  simp only [crossProduct, to_dual, LinearEquiv.trans_symm, LinearEquiv.symm_symm,
    LinearIsometryEquiv.toLinearEquiv_symm, AlternatingMap.curryLeftLinearMap, LinearMap.coe_comp,
    Function.comp_apply, LinearMap.llcomp_apply, LinearEquiv.coe_coe, LinearEquiv.trans_apply,
    LinearIsometryEquiv.coe_toLinearEquiv, LinearIsometryEquiv.norm_map, Submodule.coe_norm,
    InnerProductSpace.toDual_symm_apply, AlternatingMap.curryLeft_apply_apply,
    AlternatingMap.constLinearEquivOfIsEmpty_symm_apply, eq_self_iff_true,
    LinearMap.coe_toContinuousLinearMap', Matrix.zero_empty]

theorem inner_crossProduct_apply_self (u : E) (v : (ℝ ∙ u)ᗮ) : ⟪u×₃v, u⟫ = 0 := by
  rw [ω.inner_crossProduct_apply u v u]
  refine' ω.volumeForm.map_eq_zero_of_eq ![u, v, u] _ (by norm_num : (0 : Fin 3) ≠ 2)
  simp

theorem inner_crossProduct_apply_apply_self (u : E) (v : (ℝ ∙ u)ᗮ) : ⟪u×₃v, v⟫ = 0 := by
  rw [ω.inner_crossProduct_apply u v v]
  refine' ω.volume_form.map_eq_zero_of_eq ![u, v, v] _ (by norm_num : (1 : Fin 3) ≠ 2)
  simp

/-- The map `cross_product`, upgraded from linear to continuous-linear; useful for calculus. -/
def crossProduct' : E →L[ℝ] E →L[ℝ] E :=
  (↑(LinearMap.toContinuousLinearMap : (E →ₗ[ℝ] E) ≃ₗ[ℝ] E →L[ℝ] E) ∘ₗ
      ω.crossProduct).toContinuousLinearMap

@[simp]
theorem crossProduct'_apply (v : E) :
    ω.crossProduct' v = (ω.crossProduct v).toContinuousLinearMap :=
  rfl

theorem norm_crossProduct (u : E) (v : (ℝ ∙ u)ᗮ) : ‖u×₃v‖ = ‖u‖ * ‖v‖ := by
  classical
  refine' le_antisymm _ _
  · cases' eq_or_lt_of_le (norm_nonneg (u×₃v)) with h h
    · rw [← h]
      positivity
    refine' le_of_mul_le_mul_right _ h
    rw [← real_inner_self_eq_norm_mul_norm]
    simpa only [inner_cross_product_apply, Fin.mk_zero, Fin.prod_univ_succ, Finset.card_singleton,
      Finset.prod_const, Fintype.univ_ofSubsingleton, Matrix.cons_val_fin_one, Matrix.cons_val_succ,
      Matrix.cons_val_zero, mul_assoc, Nat.zero_eq, pow_one, Submodule.coe_norm] using
      ω.volume_form_apply_le ![u, v, u×₃v]
  let K : Submodule ℝ E := Submodule.span ℝ ({u, v} : Set E)
  have : Nontrivial Kᗮ :=
    by
    apply @FiniteDimensional.nontrivial_of_finrank_pos ℝ
    have : finrank ℝ K ≤ Finset.card {u, (v : E)} := by
      simpa [Set.toFinset_singleton] using finrank_span_le_card ({u, v} : Set E)
    have : Finset.card {u, (v : E)} ≤ Finset.card {(v : E)} + 1 := Finset.card_insert_le u {v}
    have : Finset.card {(v : E)} = 1 := Finset.card_singleton (v : E)
    have : finrank ℝ K + finrank ℝ Kᗮ = finrank ℝ E := K.finrank_add_finrank_orthogonal
    have : finrank ℝ E = 3 := Fact.out _
    linarith
  obtain ⟨w, hw⟩ : ∃ w : Kᗮ, w ≠ 0 := exists_ne 0
  have hw' : (w : E) ≠ 0 := fun h => hw (submodule.coe_eq_zero.mp h)
  have H : Pairwise fun i j => ⟪![u, v, w] i, ![u, v, w] j⟫ = 0 :=
    by
    intro i j hij
    have h1 : ⟪u, v⟫ = 0 := v.2 _ (Submodule.mem_span_singleton_self _)
    have h2 : ⟪(v : E), w⟫ = 0 := w.2 _ (Submodule.subset_span (by simp))
    have h3 : ⟪u, w⟫ = 0 := w.2 _ (Submodule.subset_span (by simp))
    fin_cases i <;> fin_cases j <;> norm_num at hij  <;> simp [h1, h2, h3] <;>
        rw [real_inner_comm] <;>
      assumption
  refine' le_of_mul_le_mul_right _ (by rwa [norm_pos_iff] : 0 < ‖w‖)
  -- Cauchy-Schwarz inequality for `u ×₃ v` and `w`
  simpa only [inner_cross_product_apply, ω.abs_volume_form_apply_of_pairwise_orthogonal H,
    inner_cross_product_apply, Fin.mk_zero, Fin.prod_univ_succ, Finset.card_singleton,
    Finset.prod_const, Fintype.univ_ofSubsingleton, Matrix.cons_val_fin_one, Matrix.cons_val_succ,
    Matrix.cons_val_zero, Nat.zero_eq, pow_one, mul_assoc] using abs_real_inner_le_norm (u×₃v) w

theorem isometry_on_crossProduct (u : Metric.sphere (0 : E) 1) (v : (ℝ ∙ (u : E))ᗮ) :
    ‖u×₃v‖ = ‖v‖ := by simp [norm_cross_product]

end Orientation

