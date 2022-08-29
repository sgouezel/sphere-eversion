import geometry.manifold.charted_space
import analysis.normed.group.basic

import to_mathlib.topology.local_homeomorph

namespace charted_space

section topological_space

open set

variables (H : Type*) (M : Type*) [topological_space H] [topological_space M] [charted_space H M]

@[simp] lemma Union_source_eq_univ : (⋃ (x : M), (chart_at H x).source) = (univ : set M) :=
begin
  refine eq_univ_iff_forall.mpr (λ x, _),
  simp only [mem_Union],
  exact ⟨x, mem_chart_source H x⟩,
end

variables {M}

lemma is_open_iff (s : set M) :
  is_open s ↔ ∀ (x : M), is_open $ chart_at H x '' ((chart_at H x).source ∩ s) :=
begin
  refine ⟨λ h x, (chart_at H x).image_open_of_open' h, λ h, _⟩,
  rw [← s.inter_univ, ← Union_source_eq_univ H M, s.inter_Union],
  refine is_open_Union (λ x, _),
  have : s ∩ (chart_at H x).source ⊆ (chart_at H x).source := inter_subset_right _ _,
  rw [(chart_at H x).is_open_image_iff_of_subset_source this, inter_comm],
  exact h x,
end

end topological_space

section normed_add_comm_group

open_locale topological_space
open metric (hiding mem_nhds_iff ball) set

variables (E : Type*) {M : Type*} [normed_add_comm_group E] [topological_space M] [charted_space E M]

def ball (x : M) (r : ℝ) := (chart_at E x).symm '' metric.ball (chart_at E x x) r

lemma nhds_has_basis_balls_of_open_cov (x : M)
  {ι : Type*} {s : ι → set M} (s_op : ∀ j, is_open $ s j) (cov : (⋃ j, s j) = univ) :
  (𝓝 x).has_basis (λ r, 0 < r ∧
                         metric.ball (chart_at E x x) r ⊆ (chart_at E x).target ∧
                         ∃ j, charted_space.ball E x r ⊆ s j)
                   (charted_space.ball E x) :=
begin
  -- MASSIVE golfing opportunity!
  obtain ⟨j, hj⟩ : ∃ j, x ∈ s j, by { simpa only [mem_Union, ← cov] using mem_univ x, },
  replace hj : s j ∈ 𝓝 x := mem_nhds_iff.mpr ⟨s j, subset.rfl, s_op j, hj⟩,
  have hx : (chart_at E x).source ∈ 𝓝 x := -- cf `ext_chart_at_source_mem_nhds`
    is_open.mem_nhds (chart_at E x).open_source (mem_chart_source E x),
  refine filter.has_basis_iff.mpr (λ n, ⟨λ hn, _, _⟩),
  { let m := s j ∩ n ∩ (chart_at E x).to_local_equiv.source,
    have hm : m ∈ 𝓝 x := filter.inter_mem (filter.inter_mem hj hn) hx,
    replace hm : (chart_at E x) '' m ∈ 𝓝 (chart_at E x x),
    { rw ← (chart_at E x).map_nhds_eq (mem_chart_source E x),
      exact filter.image_mem_map hm, },
    obtain ⟨r, hr₀, hr₁⟩ :=
      (filter.has_basis_iff.mp (@nhds_basis_ball E _ (chart_at E x x)) _).mp hm,
    refine ⟨r, ⟨hr₀, hr₁.trans _, ⟨j, _⟩⟩, _⟩,
    { exact ((chart_at E x).maps_to.mono (inter_subset_right _ _) subset.rfl).image_subset },
    { suffices : m ⊆ s j,
      { refine subset.trans _ this,
        convert monotone_image hr₁,
        exact (local_equiv.symm_image_image_of_subset_source _
          (set.inter_subset_right _ _)).symm, },
      exact (set.inter_subset_left _ _).trans (set.inter_subset_left _ _), },
    { suffices : m ⊆ n,
      { refine subset.trans _ this,
        convert monotone_image hr₁,
        exact (local_equiv.symm_image_image_of_subset_source _
          (set.inter_subset_right _ _)).symm, },
      exact (set.inter_subset_left _ _).trans (set.inter_subset_right _ _), }, },
  { rintros ⟨r, ⟨hr₀, hr₁, -⟩, hr₂⟩,
    replace hr₀ : metric.ball (chart_at E x x) r ∈ 𝓝 (chart_at E x x) := ball_mem_nhds _ hr₀,
    rw [← (chart_at E x).map_nhds_eq (mem_chart_source E x), filter.mem_map] at hr₀,
    replace hr₀ := filter.inter_mem hx hr₀,
    rw ← (chart_at E x).symm_image_eq_source_inter_preimage hr₁ at hr₀,
    filter_upwards [hr₀] using hr₂, },
end

end normed_add_comm_group

end charted_space
