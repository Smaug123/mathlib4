/-
Copyright (c) 2021 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Aurélien Saue
-/

import Lean.Expr
import Mathlib.Lean.Expr

namespace Lean

open Elab

/-- Get the declaration `nm` in the current environment. -/
def getDecl (nm : Name) : CoreM ConstantInfo := do
  let some d ← (← getEnv).find? nm | throwError "no such declaration {nm}."
  return d

/-- Make `nm` protected. -/
def setProtected {m : Type → Type} [Monad m] [MonadEnv m] (nm : Name) : m Unit := do
  modifyEnv (addProtected · nm)

namespace Parser.Tactic

-- syntax simpArg := simpStar <|> simpErase <|> simpLemma
def simpArg := simpStar.binary `orelse (simpErase.binary `orelse simpLemma)

end Parser.Tactic
end Lean
