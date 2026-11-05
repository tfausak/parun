module Parun.Codec.DealDamageSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.DealDamage as DealDamage
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamagePart as DamagePart
import qualified Parun.Types.DealDamage as DealDamage
import qualified Parun.Types.ExcessDestination as ExcessDestination
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayersWho as PlayersWho
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DealDamage" $ do
  -- CR 120.1: this much damage to the objects or players the one clause names,
  -- from the resolving object's own source (CR 113.7) when no dealer is written.
  Spec.it s "MkDealDamage, no dealer" $
    Common.assertCodec
      s
      DealDamage.codec
      ( DealDamage.MkDealDamage
          { DealDamage.parts =
              Seq.singleton
                DamagePart.MkDamagePart
                  { DamagePart.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
                    DamagePart.quantity = Quantity.Literal 3
                  },
            DealDamage.dealer = Nothing,
            DealDamage.excess = Nothing,
            DealDamage.tally = Nothing,
            DealDamage.damaged = Nothing,
            DealDamage.excessTally = Nothing
          }
      )
      " {\"parts\":[{\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"},\"quantity\":{\"type\":\"Literal\",\"value\":3}}]} "
  -- CR 120.2b's dealer, CR 120.4a's excess destination, the tally of what was
  -- dealt and the objects it reached, the keys a card writes only when its sentence says them -- over the
  -- SEVERAL clauses one instruction may name, which CR 608.2f deals as one
  -- batch, and whose amounts may differ (Char).
  Spec.it s "MkDealDamage, two clauses at different amounts plus every optional key" $
    Common.assertCodec
      s
      DealDamage.codec
      ( DealDamage.MkDealDamage
          { DealDamage.parts =
              Seq.fromList
                [ DamagePart.MkDamagePart
                    { DamagePart.ref = ObjectRef.EachMatching (Filter.HasKeyword Keyword.Flying),
                      DamagePart.quantity = Quantity.Literal 3
                    },
                  DamagePart.MkDamagePart
                    { DamagePart.ref = ObjectRef.Players (PlayersWho.MkPlayersWho (PlayerRef.Relative PlayerRelation.AnyPlayer) Nothing),
                      DamagePart.quantity = Quantity.Literal 2
                    }
                ],
            DealDamage.dealer = Just (SlotName.MkSlotName (Text.pack "dealer")),
            DealDamage.excess = Just ExcessDestination.ToRecipientController,
            DealDamage.tally = Just (SlotName.MkSlotName (Text.pack "dealt")),
            DealDamage.damaged = Just (SlotName.MkSlotName (Text.pack "hit")),
            DealDamage.excessTally = Just (SlotName.MkSlotName (Text.pack "over"))
          }
      )
      " {\"parts\":[{\"ref\":{\"type\":\"EachMatching\",\"value\":{\"type\":\"HasKeyword\",\"value\":{\"type\":\"Flying\"}}},\"quantity\":{\"type\":\"Literal\",\"value\":3}},{\"ref\":{\"type\":\"Players\",\"value\":{\"players\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}},\"quantity\":{\"type\":\"Literal\",\"value\":2}}],\"dealer\":\"dealer\",\"excess\":{\"type\":\"ToRecipientController\"},\"tally\":\"dealt\",\"damaged\":\"hit\",\"excessTally\":\"over\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DealDamage.codec
