/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes

! This file was ported from Lean 3 source module data.int.modeq
! leanprover-community/mathlib commit 2ed7e4aec72395b6a7c3ac4ac7873a7a43ead17c
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Std.Data.Int.DivMod
import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic.Ring

/-!

# Congruences modulo an integer

This file defines the equivalence relation `a ≡ b [ZMOD n]` on the integers, similarly to how
`Data.Nat.ModEq` defines them for the natural numbers. The notation is short for `n.ModEq a b`,
which is defined to be `a % n = b % n` for integers `a b n`.

## Tags

modeq, congruence, mod, MOD, modulo, integers

-/


namespace Int

/-- `a ≡ b [ZMOD n]` when `a % n = b % n`. -/
def ModEq (n a b : ℤ) :=
  a % n = b % n
#align int.modeq Int.ModEq

@[inherit_doc]
notation:50 a " ≡ " b " [ZMOD " n "]" => ModEq n a b

variable {m n a b c d : ℤ}

-- Porting note: This instance should be derivable automatically
instance : Decidable (ModEq n a b) := decEq (a % n) (b % n)

namespace ModEq

@[refl]
protected theorem refl (a : ℤ) : a ≡ a [ZMOD n] :=
  @rfl _ _
#align int.modeq.refl Int.ModEq.refl

protected theorem rfl : a ≡ a [ZMOD n] :=
  ModEq.refl _
#align int.modeq.rfl Int.ModEq.rfl

instance : IsRefl _ (ModEq n) :=
  ⟨ModEq.refl⟩

@[symm]
protected theorem symm : a ≡ b [ZMOD n] → b ≡ a [ZMOD n] :=
  Eq.symm
#align int.modeq.symm Int.ModEq.symm

@[trans]
protected theorem trans : a ≡ b [ZMOD n] → b ≡ c [ZMOD n] → a ≡ c [ZMOD n] :=
  Eq.trans
#align int.modeq.trans Int.ModEq.trans

instance : Trans (ModEq n) (ModEq n) (ModEq n) where
  trans := Int.ModEq.trans

end ModEq

theorem coe_nat_modEq_iff {a b n : ℕ} : a ≡ b [ZMOD n] ↔ a ≡ b [MOD n] := by
  unfold ModEq Nat.ModEq; rw [← Int.ofNat_inj]; simp [coe_nat_mod]
#align int.coe_nat_modeq_iff Int.coe_nat_modEq_iff

theorem modEq_zero_iff_dvd : a ≡ 0 [ZMOD n] ↔ n ∣ a := by
  rw [ModEq, zero_emod, dvd_iff_emod_eq_zero]
#align int.modeq_zero_iff_dvd Int.modEq_zero_iff_dvd

theorem _root_.Dvd.dvd.modEq_zero_int (h : n ∣ a) : a ≡ 0 [ZMOD n] :=
  modEq_zero_iff_dvd.2 h
#align has_dvd.dvd.modeq_zero_int Dvd.dvd.modEq_zero_int

theorem _root_.Dvd.dvd.zero_modEq_int (h : n ∣ a) : 0 ≡ a [ZMOD n] :=
  h.modEq_zero_int.symm
#align has_dvd.dvd.zero_modeq_int Dvd.dvd.zero_modEq_int

theorem modEq_iff_dvd : a ≡ b [ZMOD n] ↔ n ∣ b - a := by
  rw [ModEq, eq_comm]
  simp [emod_eq_emod_iff_emod_sub_eq_zero, dvd_iff_emod_eq_zero]

#align int.modeq_iff_dvd Int.modEq_iff_dvd

theorem modEq_iff_add_fac {a b n : ℤ} : a ≡ b [ZMOD n] ↔ ∃ t, b = a + n * t :=
  by
  rw [modEq_iff_dvd]
  exact exists_congr fun t => sub_eq_iff_eq_add'
#align int.modeq_iff_add_fac Int.modEq_iff_add_fac

alias modEq_iff_dvd ↔ ModEq.dvd modEq_of_dvd
#align int.modeq.dvd Int.ModEq.dvd
#align int.modeq_of_dvd Int.modEq_of_dvd

theorem mod_modEq (a n) : a % n ≡ a [ZMOD n] :=
  emod_emod _ _
#align int.mod_modeq Int.mod_modEq

namespace ModEq

protected theorem of_dvd (d : m ∣ n) (h : a ≡ b [ZMOD n]) : a ≡ b [ZMOD m] :=
  modEq_iff_dvd.2 <| d.trans h.dvd
#align int.modeq.of_dvd Int.ModEq.of_dvd

protected theorem mul_left' (hc : 0 ≤ c) (h : a ≡ b [ZMOD n]) : c * a ≡ c * b [ZMOD c * n] :=
  match hc.lt_or_eq with
  | .inl hc => by
    unfold ModEq
    simp [mul_emod_mul_of_pos _ _ hc, show _ = _ from h]
  | .inr hc => by
    simp [hc.symm]
#align int.modeq.mul_left' Int.ModEq.mul_left'

protected theorem mul_right' (hc : 0 ≤ c) (h : a ≡ b [ZMOD n]) : a * c ≡ b * c [ZMOD n * c] := by
  rw [mul_comm a, mul_comm b, mul_comm n]; exact h.mul_left' hc
#align int.modeq.mul_right' Int.ModEq.mul_right'

protected theorem add (h₁ : a ≡ b [ZMOD n]) (h₂ : c ≡ d [ZMOD n]) : a + c ≡ b + d [ZMOD n] :=
  modEq_iff_dvd.2 <| by
    convert dvd_add h₁.dvd h₂.dvd
    ring
#align int.modeq.add Int.ModEq.add

protected theorem add_left (c : ℤ) (h : a ≡ b [ZMOD n]) : c + a ≡ c + b [ZMOD n] :=
  ModEq.rfl.add h
#align int.modeq.add_left Int.ModEq.add_left

protected theorem add_right (c : ℤ) (h : a ≡ b [ZMOD n]) : a + c ≡ b + c [ZMOD n] :=
  h.add ModEq.rfl
#align int.modeq.add_right Int.ModEq.add_right

protected theorem add_left_cancel (h₁ : a ≡ b [ZMOD n]) (h₂ : a + c ≡ b + d [ZMOD n]) :
    c ≡ d [ZMOD n] :=
  have : d - c = b + d - (a + c) - (b - a) := by ring
  modEq_iff_dvd.2 <| by
    rw [this]
    exact dvd_sub h₂.dvd h₁.dvd
#align int.modeq.add_left_cancel Int.ModEq.add_left_cancel

protected theorem add_left_cancel' (c : ℤ) (h : c + a ≡ c + b [ZMOD n]) : a ≡ b [ZMOD n] :=
  ModEq.rfl.add_left_cancel h
#align int.modeq.add_left_cancel' Int.ModEq.add_left_cancel'

protected theorem add_right_cancel (h₁ : c ≡ d [ZMOD n]) (h₂ : a + c ≡ b + d [ZMOD n]) :
    a ≡ b [ZMOD n] := by
  rw [add_comm a, add_comm b] at h₂
  exact h₁.add_left_cancel h₂
#align int.modeq.add_right_cancel Int.ModEq.add_right_cancel

protected theorem add_right_cancel' (c : ℤ) (h : a + c ≡ b + c [ZMOD n]) : a ≡ b [ZMOD n] :=
  ModEq.rfl.add_right_cancel h
#align int.modeq.add_right_cancel' Int.ModEq.add_right_cancel'

protected theorem neg (h : a ≡ b [ZMOD n]) : -a ≡ -b [ZMOD n] :=
  h.add_left_cancel (by simp_rw [← sub_eq_add_neg, sub_self]; rfl)
#align int.modeq.neg Int.ModEq.neg

protected theorem sub (h₁ : a ≡ b [ZMOD n]) (h₂ : c ≡ d [ZMOD n]) : a - c ≡ b - d [ZMOD n] :=
  by
  rw [sub_eq_add_neg, sub_eq_add_neg]
  exact h₁.add h₂.neg
#align int.modeq.sub Int.ModEq.sub

protected theorem sub_left (c : ℤ) (h : a ≡ b [ZMOD n]) : c - a ≡ c - b [ZMOD n] :=
  ModEq.rfl.sub h
#align int.modeq.sub_left Int.ModEq.sub_left

protected theorem sub_right (c : ℤ) (h : a ≡ b [ZMOD n]) : a - c ≡ b - c [ZMOD n] :=
  h.sub ModEq.rfl
#align int.modeq.sub_right Int.ModEq.sub_right

protected theorem mul_left (c : ℤ) (h : a ≡ b [ZMOD n]) : c * a ≡ c * b [ZMOD n] :=
  match (le_total 0 c) with
  | .inl hc => (h.mul_left' hc).of_dvd (dvd_mul_left _ _)
  | .inr hc => by
    rw [← neg_neg c, neg_mul, neg_mul _ b]
    exact ((h.mul_left' <| neg_nonneg.2 hc).of_dvd (dvd_mul_left _ _)).neg
#align int.modeq.mul_left Int.ModEq.mul_left

protected theorem mul_right (c : ℤ) (h : a ≡ b [ZMOD n]) : a * c ≡ b * c [ZMOD n] :=
  by
  rw [mul_comm a, mul_comm b]
  exact h.mul_left c
#align int.modeq.mul_right Int.ModEq.mul_right

protected theorem mul (h₁ : a ≡ b [ZMOD n]) (h₂ : c ≡ d [ZMOD n]) : a * c ≡ b * d [ZMOD n] :=
  (h₂.mul_left _).trans (h₁.mul_right _)
#align int.modeq.mul Int.ModEq.mul

protected theorem pow (m : ℕ) (h : a ≡ b [ZMOD n]) : a ^ m ≡ b ^ m [ZMOD n] :=
  by
  induction' m with d hd; · rfl
  rw [pow_succ, pow_succ]
  exact h.mul hd
#align int.modeq.pow Int.ModEq.pow

lemma of_mul_left (m : ℤ) (h : a ≡ b [ZMOD m * n]) : a ≡ b [ZMOD n] := by
  rw [modEq_iff_dvd] at *; exact (dvd_mul_left n m).trans h
#align int.modeq.of_mul_left Int.ModEq.of_mul_left

lemma of_mul_right (m : ℤ) : a ≡ b [ZMOD n * m] → a ≡ b [ZMOD n] :=
  mul_comm m n ▸ of_mul_left _
#align int.modeq.of_mul_right Int.ModEq.of_mul_right

end ModEq

theorem modEq_one : a ≡ b [ZMOD 1] :=
  modEq_of_dvd (one_dvd _)
#align int.modeq_one Int.modEq_one

theorem modEq_sub (a b : ℤ) : a ≡ b [ZMOD a - b] :=
  (modEq_of_dvd dvd_rfl).symm
#align int.modeq_sub Int.modEq_sub

theorem modEq_and_modEq_iff_modEq_mul {a b m n : ℤ} (hmn : m.natAbs.coprime n.natAbs) :
    a ≡ b [ZMOD m] ∧ a ≡ b [ZMOD n] ↔ a ≡ b [ZMOD m * n] :=
  ⟨fun h => by
    rw [modEq_iff_dvd, modEq_iff_dvd] at h
    rw [modEq_iff_dvd, ← natAbs_dvd, ← dvd_natAbs, coe_nat_dvd, natAbs_mul]
    refine' hmn.mul_dvd_of_dvd_of_dvd _ _ <;> rw [← coe_nat_dvd, natAbs_dvd, dvd_natAbs] <;>
      tauto,
    fun h => ⟨h.of_mul_right _, h.of_mul_left _⟩⟩
#align int.modeq_and_modeq_iff_modeq_mul Int.modEq_and_modEq_iff_modEq_mul

theorem gcd_a_modEq (a b : ℕ) : (a : ℤ) * Nat.gcdA a b ≡ Nat.gcd a b [ZMOD b] :=
  by
  rw [← add_zero ((a : ℤ) * _), Nat.gcd_eq_gcd_ab]
  exact (dvd_mul_right _ _).zero_modEq_int.add_left _
#align int.gcd_a_modeq Int.gcd_a_modEq

theorem modEq_add_fac {a b n : ℤ} (c : ℤ) (ha : a ≡ b [ZMOD n]) : a + n * c ≡ b [ZMOD n] :=
  calc
    a + n * c ≡ b + n * c [ZMOD n] := ha.add_right _
    _ ≡ b + 0 [ZMOD n] := (dvd_mul_right _ _).modEq_zero_int.add_left _
    _ ≡ b [ZMOD n] := by rw [add_zero]

#align int.modeq_add_fac Int.modEq_add_fac

theorem modEq_add_fac_self {a t n : ℤ} : a + n * t ≡ a [ZMOD n] :=
  modEq_add_fac _ ModEq.rfl
#align int.modeq_add_fac_self Int.modEq_add_fac_self

theorem mod_coprime {a b : ℕ} (hab : Nat.coprime a b) : ∃ y : ℤ, a * y ≡ 1 [ZMOD b] :=
  ⟨Nat.gcdA a b,
    have hgcd : Nat.gcd a b = 1 := Nat.coprime.gcd_eq_one hab
    calc
      ↑a * Nat.gcdA a b ≡ ↑a * Nat.gcdA a b + ↑b * Nat.gcdB a b [ZMOD ↑b] :=
        ModEq.symm <| modEq_add_fac _ <| ModEq.refl _
      _ ≡ 1 [ZMOD ↑b] := by rw [← Nat.gcd_eq_gcd_ab, hgcd]; rfl
      ⟩
#align int.mod_coprime Int.mod_coprime

theorem exists_unique_equiv (a : ℤ) {b : ℤ} (hb : 0 < b) :
    ∃ z : ℤ, 0 ≤ z ∧ z < b ∧ z ≡ a [ZMOD b] :=
  ⟨a % b, emod_nonneg _ (ne_of_gt hb),
    by
    have : a % b < |b| := emod_lt _ (ne_of_gt hb)
    rwa [abs_of_pos hb] at this, by simp [ModEq]⟩
#align int.exists_unique_equiv Int.exists_unique_equiv

theorem exists_unique_equiv_nat (a : ℤ) {b : ℤ} (hb : 0 < b) : ∃ z : ℕ, ↑z < b ∧ ↑z ≡ a [ZMOD b] :=
  let ⟨z, hz1, hz2, hz3⟩ := exists_unique_equiv a hb
  ⟨z.natAbs, by
    constructor <;> rw [ofNat_natAbs_eq_of_nonneg z hz1] <;> assumption⟩
#align int.exists_unique_equiv_nat Int.exists_unique_equiv_nat

theorem mod_mul_right_mod (a b c : ℤ) : a % (b * c) % b = a % b :=
  (mod_modEq _ _).of_mul_right _
#align int.mod_mul_right_mod Int.mod_mul_right_mod

theorem mod_mul_left_mod (a b c : ℤ) : a % (b * c) % c = a % c :=
  (mod_modEq _ _).of_mul_left _
#align int.mod_mul_left_mod Int.mod_mul_left_mod

end Int
