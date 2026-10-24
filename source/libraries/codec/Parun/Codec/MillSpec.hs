module Parun.Codec.MillSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Mill as Mill
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Mill as Mill
import qualified Parun.Types.MillTally as MillTally
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Mill" $ do
  -- Every mill in the pool but rule 728.1's looks back at nothing, so the tally
  -- key is absent here and present below.
  Spec.it s "MkMill, no tally: the key is omitted" $
    Common.assertCodec
      s
      Mill.codec
      (Mill.MkMill (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal 3) Nothing Nothing)
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"quantity\":{\"type\":\"Literal\",\"value\":3}} "
  Spec.it s "MkMill, CR 728.1's tally: the key is written" $
    Common.assertCodec
      s
      Mill.codec
      ( Mill.MkMill
          (PlayerRef.Relative PlayerRelation.You)
          (Quantity.Literal 2)
          (Just (MillTally.MkMillTally (SlotName.MkSlotName (Text.pack "milled")) (Filter.Not (Filter.HasCardType CardType.Land))))
          Nothing
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"quantity\":{\"type\":\"Literal\",\"value\":2},\"tally\":{\"slot\":\"milled\",\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}}} "
  -- CR 701.17c's slot, which Midnight Tilling writes and the tally-carrying
  -- printing does not: the two keys are independent.
  Spec.it s "MkMill, CR 701.17c's slot: the key is written" $
    Common.assertCodec
      s
      Mill.codec
      ( Mill.MkMill
          (PlayerRef.Relative PlayerRelation.You)
          (Quantity.Literal 4)
          Nothing
          (Just (SlotName.MkSlotName (Text.pack "milled")))
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"quantity\":{\"type\":\"Literal\",\"value\":4},\"slot\":\"milled\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Mill.codec
