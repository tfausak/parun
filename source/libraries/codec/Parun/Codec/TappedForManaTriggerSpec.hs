module Parun.Codec.TappedForManaTriggerSpec where

import qualified Parun.Codec.TappedForManaTrigger as TappedForManaTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaSpecification as ManaSpecification
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.TappedForManaTrigger as TappedForManaTrigger
import qualified Parun.Types.TappedPermanent as TappedPermanent

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TappedForManaTrigger" $ do
  -- Autumn Willow, Harmony's payload: the quality the tapped permanent has to
  -- have, whose tap fires it, and the mana narrowing its printed sentence does
  -- not make.
  Spec.it s "MkTappedForManaTrigger, every key" $
    Common.assertCodec
      s
      TappedForManaTrigger.codec
      ( TappedForManaTrigger.MkTappedForManaTrigger
          { TappedForManaTrigger.permanent = TappedPermanent.Matching (Filter.HasCardType CardType.Land),
            TappedForManaTrigger.player = PlayerRelation.You,
            TappedForManaTrigger.mana = ManaSpecification.AnyMana
          }
      )
      " {\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}},\"player\":{\"type\":\"You\"},\"mana\":{\"type\":\"AnyMana\"}} "
  -- Gauntlet of Power's narrowing, on a payload differing from the one above in
  -- all three keys: a codec that defaulted the mana rather than reading it would
  -- encode the two alike.
  Spec.it s "MkTappedForManaTrigger, a narrowed one" $
    Common.assertCodec
      s
      TappedForManaTrigger.codec
      ( TappedForManaTrigger.MkTappedForManaTrigger
          { TappedForManaTrigger.permanent = TappedPermanent.Matching (Filter.HasSupertype Supertype.Basic),
            TappedForManaTrigger.player = PlayerRelation.AnyPlayer,
            TappedForManaTrigger.mana = ManaSpecification.ChosenColor
          }
      )
      " {\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasSupertype\",\"value\":{\"type\":\"Basic\"}}},\"player\":{\"type\":\"AnyPlayer\"},\"mana\":{\"type\":\"ChosenColor\"}} "
  -- Wild Growth's: the attachment link, any tapping player, any mana.
  Spec.it s "MkTappedForManaTrigger, an attached one" $
    Common.assertCodec
      s
      TappedForManaTrigger.codec
      (TappedForManaTrigger.MkTappedForManaTrigger TappedPermanent.Attached PlayerRelation.AnyPlayer ManaSpecification.AnyMana)
      " {\"permanent\":{\"type\":\"Attached\"},\"player\":{\"type\":\"AnyPlayer\"},\"mana\":{\"type\":\"AnyMana\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TappedForManaTrigger.codec
