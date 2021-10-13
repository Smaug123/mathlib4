/-
Copyright (c) 2021 Gabriel Ebner. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Gabriel Ebner
-/
import Mathlib.Tactic.Cache
import Mathlib.Tactic.SolveByElim
import Mathlib.Tactic.OpenPrivate

/-!
# Library search

This file defines a tactic `librarySearch`
and a term elaborator `librarySearch%`
that tries to find a lemma
solving the current goal
(subgoals are solved using `solveByElim`).

```
example : x < x + 1 := librarySearch%
example : Nat := by librarySearch
```
-/

namespace Tactic
namespace LibrarySearch

open Lean Meta

initialize registerTraceClass `Tactic.librarySearch

-- from Lean.Server.Completion
private def isBlackListed (declName : Name) : MetaM Bool := do
  if declName matches Name.str _ "inj" _ then return false
  if declName matches Name.str _ "noConfusionType" _ then return false
  let env ← getEnv
  declName.isInternal
  <||> isAuxRecursor env declName
  <||> isNoConfusion env declName
  <||> isRec declName <||> isMatcher declName

initialize librarySearchLemmas : DeclCache (DiscrTree Name) ←
  DeclCache.mk "librarySearch: init cache" {} fun name constInfo lemmas => do
    if constInfo.isUnsafe then return lemmas
    if ← isBlackListed name then return lemmas
    withNewMCtxDepth do
      let (xs, bis, type) ← withReducible <| forallMetaTelescopeReducing constInfo.type
      let keys ← withReducible <| DiscrTree.mkPath type
      lemmas.insertCore keys name

def librarySearch (mvarId : MVarId) (lemmas : DiscrTree Name) (solveByElimDepth := 6) :
    MetaM <| Option (Array <| MetavarContext × List MVarId) := do
  profileitM Exception "librarySearch" (← getOptions) do
  let mvar := mkMVar mvarId
  let ty ← inferType mvar

  let mut suggestions := #[]

  let state0 ← get

  try
    solveByElim solveByElimDepth mvarId
    return none
  catch _ =>
    set state0

  for lem in ← lemmas.getMatch ty do
    trace[Tactic.librarySearch] "{lem}"
    match ← traceCtx `Tactic.librarySearch try
        let newMVars ← apply mvarId (← mkConstWithFreshMVarLevels lem)
        (try
          for newMVar in newMVars do
            withMVarContext newMVar do
              trace[Tactic.librarySearch] "proving {← addMessageContextFull (mkMVar newMVar)}"
              solveByElim solveByElimDepth newMVar
          some (Sum.inr ())
        catch _ =>
          let res := some (Sum.inl <| (← getMCtx, newMVars))
          set state0
          res)
      catch _ =>
        set state0
        none
      with
      | none => ()
      | some (Sum.inr ()) => return none
      | some (Sum.inl suggestion) => suggestions := suggestions.push suggestion

  some suggestions

def lines (ls : List MessageData) :=
  MessageData.joinSep ls (MessageData.ofFormat Format.line)

open Elab.Tactic Elab Tactic in
elab "librarySearch" : tactic =>do
  withNestedTraces do
  trace[Tactic.librarySearch] "proving {← getMainTarget}"
  let mvar ← getMainGoal
  let (hs, introdMVar) ← intros (← getMainGoal)
  withMVarContext introdMVar do
    if let some suggestions ← librarySearch introdMVar (← librarySearchLemmas.get) then
      logError <| lines <|<- suggestions.toList.mapM fun (mctx, _) =>
        withMCtx mctx do addMessageContextFull <|<- do
          m!"{← mkLambdaFVars (hs.map (mkFVar ·)) <|<-
            instantiateMVars <| mkMVar introdMVar}"
    else
      logInfo <|<- instantiateMVars <| mkMVar mvar

open Elab Term in
elab "librarySearch%" : term <= expectedType => do
  withNestedTraces do
  trace[Tactic.librarySearch] "proving {expectedType}"
  let mvar ← mkFreshExprMVar expectedType
  let (hs, introdMVar) ← intros mvar.mvarId!
  withMVarContext introdMVar do
    if let some suggestions ← librarySearch introdMVar (← librarySearchLemmas.get) then
      throwError "{lines <|<- suggestions.toList.mapM fun (mctx, _) =>
        withMCtx mctx do addMessageContextFull <|<- do
          m!"{← mkLambdaFVars (hs.map (mkFVar ·)) <|<-
            instantiateMVars <| mkMVar introdMVar}"}" -- "
    else
      logInfo <|<- instantiateMVars <| mvar
  instantiateMVars mvar
