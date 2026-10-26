-- The recursion of Parun.Engine.Resolve.Effect that applyOneEffect's arms call
-- back into, so Parun.Engine.Resolve.Arms compiles ahead of it. GHC checks each
-- signature against the module's own.
module Parun.Engine.Resolve.Effect where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import Data.Set (Set)
import Numeric.Natural (Natural)
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CastObligation as CastObligation
import qualified Parun.Types.CastOffer as CastOffer
import qualified Parun.Types.CastRepetition as CastRepetition
import Parun.Types.Effect (Effect)
import Parun.Types.Game (Game)
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.HandActionPerformer as HandActionPerformer
import qualified Parun.Types.ManaAbilityPerformer as ManaAbilityPerformer
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Types.PermissionVerb as PermissionVerb
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PrintingId as PrintingId
import qualified Parun.Types.Quantity as Quantity.Type
import Parun.Types.Recipient (Recipient)
import Parun.Types.Result (Result)
import Parun.Types.SlotName (SlotName)
import qualified Parun.Types.Throw as Throw

offerCast :: Game Result -> Filter.Context -> (Quantity.Type.Quantity -> Maybe Integer) -> [ObjectId] -> PlayerId -> CastObligation.CastObligation -> PermissionVerb.PermissionVerb -> Maybe PlayerId -> CastRepetition.CastRepetition -> Bool -> CastOffer.CastOffer -> Game [ObjectId]
offerOutsideCopy :: Game Result -> Filter.Context -> PlayerId -> PrintingId.PrintingId -> CastOffer.CastOffer -> Game ()
applyEffectWith :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
applyOneEffect :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Game ()
runPreventionRiders :: Game Result -> Game ()
runReplacementEffects :: Game Result -> Game ()
runDamageRewriteEffect :: Game Result -> PendingReplacementEffect.PendingReplacementEffect -> Game ()
performHandAction :: Game Result -> HandActionPerformer.HandActionPerformer
throwDice :: Game Result -> PlayerId -> Natural -> Natural -> Game Integer -> Game ([Natural], [PlayerId], [Natural])
throwForCoin :: Game Result -> Throw.Throw -> Game [Natural]
performManaAbility :: Game Result -> ManaAbilityPerformer.ManaAbilityPerformer
applyLoopBody :: Game Result -> ObjectId -> ObjectId -> PlayerId -> Map.Map SlotName (Set Recipient) -> Map.Map SlotName (Set Recipient) -> Set SlotName -> Seq.Seq (Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Game ()
loopOffers :: Game Result -> ObjectId -> ObjectId -> PlayerId -> SlotName -> Map.Map SlotName (Set Recipient) -> [Recipient] -> PayGate.PayGate -> Game [Recipient]
