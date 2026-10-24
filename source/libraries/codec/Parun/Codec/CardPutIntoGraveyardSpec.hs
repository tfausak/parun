module Parun.Codec.CardPutIntoGraveyardSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.CardPutIntoGraveyard as CardPutIntoGraveyard
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardPutIntoGraveyard as CardPutIntoGraveyard
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CardPutIntoGraveyard" $ do
  -- Planar Void's payload: from anywhere.
  Spec.it s "MkCardPutIntoGraveyard, from anywhere" $
    Common.assertCodec
      s
      CardPutIntoGraveyard.codec
      (CardPutIntoGraveyard.MkCardPutIntoGraveyard {CardPutIntoGraveyard.filter = Filter.Not Filter.IsSource, CardPutIntoGraveyard.from = Set.empty})
      " {\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}}} "
  -- Oglor, Devoted Assistant's: "into your graveyard from your library or hand".
  Spec.it s "MkCardPutIntoGraveyard, from named zones" $
    Common.assertCodec
      s
      CardPutIntoGraveyard.codec
      (CardPutIntoGraveyard.MkCardPutIntoGraveyard {CardPutIntoGraveyard.filter = Filter.OwnedBy PlayerRelation.You, CardPutIntoGraveyard.from = Set.fromList [Zone.Hand, Zone.Library]})
      " {\"filter\":{\"type\":\"OwnedBy\",\"value\":{\"type\":\"You\"}},\"from\":[{\"type\":\"Library\"},{\"type\":\"Hand\"}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CardPutIntoGraveyard.codec
