module Pawl.Codec.ExileFromGraveyardSpec where

import qualified Pawl.Codec.ExileFromGraveyard as ExileFromGraveyard
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.ExileFromGraveyard as ExileFromGraveyard
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.HowMany as HowMany
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ExileFromGraveyard" $ do
  -- Living Lore: one card out of your graveyard, both defaults elided.
  Spec.it s "MkExileFromGraveyard, the defaults" $
    Common.assertCodec
      s
      ExileFromGraveyard.codec
      ( ExileFromGraveyard.MkExileFromGraveyard
          { ExileFromGraveyard.filter = Filter.HasCardType CardType.Instant,
            ExileFromGraveyard.players = PlayerScope.Related PlayerRelation.You,
            ExileFromGraveyard.count = HowMany.one
          }
      )
      " {\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Instant\"}}} "
  -- Sutured Ghoul's "any number" and Dermotaxi's "a graveyard".
  Spec.it s "MkExileFromGraveyard, any number out of any graveyard" $
    Common.assertCodec
      s
      ExileFromGraveyard.codec
      ( ExileFromGraveyard.MkExileFromGraveyard
          { ExileFromGraveyard.filter = Filter.HasCardType CardType.Creature,
            ExileFromGraveyard.players = PlayerScope.Related PlayerRelation.AnyPlayer,
            ExileFromGraveyard.count = HowMany.UpTo Nothing
          }
      )
      " {\"count\":{\"type\":\"UpTo\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"players\":{\"type\":\"AnyPlayer\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExileFromGraveyard.codec
