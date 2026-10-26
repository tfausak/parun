module Parun.Codec.CastFromZoneSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CastFromZone as CastFromZone
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CastFromZone as CastFromZone
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CounterSpread as CounterSpread
import qualified Parun.Types.CountersFromPermanents as CountersFromPermanents
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.PermissionLimit as PermissionLimit
import qualified Parun.Types.PermissionPool as PermissionPool
import qualified Parun.Types.PermissionVerb as PermissionVerb
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.WhichCounters as WhichCounters
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CastFromZone" $ do
  -- Yawgmoth's Will's shape: your own graveyard, every card in it.
  Spec.it s "MkCastFromZone, both keys" $
    Common.assertCodec
      s
      CastFromZone.codec
      ( CastFromZone.MkCastFromZone
          { CastFromZone.from = InZone.MkInZone {InZone.zone = Zone.Graveyard, InZone.player = PlayerRef.Relative PlayerRelation.You},
            CastFromZone.matching = Filter.And [],
            CastFromZone.limit = PermissionLimit.Unlimited,
            CastFromZone.verb = PermissionVerb.Cast,
            CastFromZone.pool = PermissionPool.EveryCard,
            CastFromZone.additionalCosts = [],
            CastFromZone.reduction = 0
          }
      )
      " {\"from\":{\"zone\":{\"type\":\"Graveyard\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"matching\":{\"type\":\"And\",\"value\":[]}} "
  -- Sen Triplets' shape: the hand of the player a target slot named.
  Spec.it s "a slot names whose zone" $
    Common.assertCodec
      s
      CastFromZone.codec
      ( CastFromZone.MkCastFromZone
          { CastFromZone.from = InZone.MkInZone {InZone.zone = Zone.Hand, InZone.player = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "opponent"))},
            CastFromZone.matching = Filter.HasCardType CardType.Creature,
            CastFromZone.limit = PermissionLimit.Unlimited,
            CastFromZone.verb = PermissionVerb.Cast,
            CastFromZone.pool = PermissionPool.EveryCard,
            CastFromZone.additionalCosts = [],
            CastFromZone.reduction = 0
          }
      )
      " {\"from\":{\"zone\":{\"type\":\"Hand\"},\"player\":{\"type\":\"InSlot\",\"value\":\"opponent\"}},\"matching\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Johann, Apprentice Sorcerer's shape: the top of your own library, once each
  -- turn. The key the two cases above omit, which is what says the default is a
  -- default and not the only value that decodes.
  Spec.it s "a once-each-turn budget" $
    Common.assertCodec
      s
      CastFromZone.codec
      ( CastFromZone.MkCastFromZone
          { CastFromZone.from = InZone.MkInZone {InZone.zone = Zone.Library, InZone.player = PlayerRef.Relative PlayerRelation.You},
            CastFromZone.matching = Filter.And [],
            CastFromZone.limit = PermissionLimit.OnceEachTurn,
            CastFromZone.verb = PermissionVerb.Cast,
            CastFromZone.pool = PermissionPool.EveryCard,
            CastFromZone.additionalCosts = [],
            CastFromZone.reduction = 0
          }
      )
      " {\"from\":{\"zone\":{\"type\":\"Library\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"matching\":{\"type\":\"And\",\"value\":[]},\"limit\":{\"type\":\"OnceEachTurn\"}} "
  -- Serra Paragon's shape: your own graveyard, once during each of your turns,
  -- a land played or a spell cast.
  Spec.it s "a play verb" $
    Common.assertCodec
      s
      CastFromZone.codec
      ( CastFromZone.MkCastFromZone
          { CastFromZone.from = InZone.MkInZone {InZone.zone = Zone.Graveyard, InZone.player = PlayerRef.Relative PlayerRelation.You},
            CastFromZone.matching = Filter.And [],
            CastFromZone.limit = PermissionLimit.OnceEachOfYourTurns,
            CastFromZone.verb = PermissionVerb.Play,
            CastFromZone.pool = PermissionPool.EveryCard,
            CastFromZone.additionalCosts = [],
            CastFromZone.reduction = 0
          }
      )
      " {\"from\":{\"zone\":{\"type\":\"Graveyard\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"matching\":{\"type\":\"And\",\"value\":[]},\"limit\":{\"type\":\"OnceEachOfYourTurns\"},\"verb\":{\"type\":\"Play\"}} "
  -- Dawnhand Dissident's shape: the cards exiled with it, for three counters
  -- removed from among your creatures on top of the spell's other costs.
  Spec.it s "a linked pool and an additional cost" $
    Common.assertCodec
      s
      CastFromZone.codec
      ( CastFromZone.MkCastFromZone
          { CastFromZone.from = InZone.MkInZone {InZone.zone = Zone.Exile, InZone.player = PlayerRef.Relative PlayerRelation.AnyPlayer},
            CastFromZone.matching = Filter.HasCardType CardType.Creature,
            CastFromZone.limit = PermissionLimit.Unlimited,
            CastFromZone.verb = PermissionVerb.Cast,
            CastFromZone.pool = PermissionPool.InExiledPile ExiledPile.OwnAbilities,
            CastFromZone.reduction = 0,
            CastFromZone.additionalCosts = [CostComponent.RemoveCounters (CountersFromPermanents.MkCountersFromPermanents (CostAmount.Fixed 3) WhichCounters.OfAnyKind (Filter.And [Filter.HasCardType CardType.Creature, Filter.HeldBy Holder.Controller PlayerRelation.You]) CounterSpread.FromAmong)]
          }
      )
      " {\"from\":{\"zone\":{\"type\":\"Exile\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}},\"matching\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"pool\":{\"type\":\"InExiledPile\",\"value\":{\"type\":\"OwnAbilities\"}},\"additionalCosts\":[{\"type\":\"RemoveCounters\",\"value\":{\"count\":{\"type\":\"Fixed\",\"value\":3},\"kind\":{\"type\":\"OfAnyKind\"},\"spread\":{\"type\":\"FromAmong\"},\"whichPermanent\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}]}}}]} "
  -- Urianger Augurelt's Play Arcanum: cards exiled with the source, played this
  -- turn, and a spell cast this way costs {2} less (CR 601.2f).
  Spec.it s "a reduction" $
    Common.assertCodec
      s
      CastFromZone.codec
      ( CastFromZone.MkCastFromZone
          { CastFromZone.from = InZone.MkInZone {InZone.zone = Zone.Exile, InZone.player = PlayerRef.Relative PlayerRelation.AnyPlayer},
            CastFromZone.matching = Filter.And [],
            CastFromZone.limit = PermissionLimit.Unlimited,
            CastFromZone.verb = PermissionVerb.Play,
            CastFromZone.pool = PermissionPool.InExiledPile ExiledPile.OwnAbilities,
            CastFromZone.additionalCosts = [],
            CastFromZone.reduction = 2
          }
      )
      " {\"from\":{\"zone\":{\"type\":\"Exile\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}},\"matching\":{\"type\":\"And\",\"value\":[]},\"verb\":{\"type\":\"Play\"},\"pool\":{\"type\":\"InExiledPile\",\"value\":{\"type\":\"OwnAbilities\"}},\"reduction\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CastFromZone.codec
