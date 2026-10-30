module Parun.Codec.Aggregation where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.DistinctOf as DistinctOf
import qualified Parun.Codec.Trait as Trait
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Aggregation as Aggregation

-- | No longer wholly nullary: Greatest carries the per-member quantity it
-- reads. Parametric in that quantity, exactly as 'Aggregation.Aggregation' is,
-- so the codec reaches the payload only through the codec passed in -- which is
-- what lets this module sit below @Parun.Codec.Quantity@ rather than in a cycle
-- with it.
--
-- Converting this forces 'Parun.Codec.Count' and 'Parun.Codec.Quantity' to convert
-- with it: a parametric codec needs a @Codec q@ where the loose pair needed only
-- an encode\/decode function, and that requirement propagates up every
-- parametric caller (#1306).
codec :: (Typeable.Typeable q, Eq q) => Codec.Codec q -> Codec.Codec (Aggregation.Aggregation q)
codec quantityCodec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Members" Aggregation.Members,
      Arm.payload "Distinct" DistinctOf.codec Aggregation.Distinct (\x -> case x of Aggregation.Distinct y -> Just y; _ -> Nothing),
      Arm.payload "MostSharing" Trait.codec Aggregation.MostSharing (\x -> case x of Aggregation.MostSharing y -> Just y; _ -> Nothing),
      Arm.nullary "DistinctNames" Aggregation.DistinctNames,
      Arm.payload "Greatest" quantityCodec Aggregation.Greatest (\x -> case x of Aggregation.Greatest y -> Just y; _ -> Nothing),
      Arm.payload "Total" quantityCodec Aggregation.Total (\x -> case x of Aggregation.Total y -> Just y; _ -> Nothing)
    ]

tagOf :: Aggregation.Aggregation q -> String
tagOf x = case x of
  Aggregation.Members {} -> "Members"
  Aggregation.Distinct {} -> "Distinct"
  Aggregation.MostSharing {} -> "MostSharing"
  Aggregation.DistinctNames {} -> "DistinctNames"
  Aggregation.Greatest {} -> "Greatest"
  Aggregation.Total {} -> "Total"
