module Parun.Codec.Affected where

import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Affected as Affected

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec Affected.Affected
codec =
  let filterCodec = Filter.codec Keyword.codec
   in Arm.tagged
        tagOf
        [ Arm.payload "TheseObjects" (Common.set ObjectId.codec) Affected.TheseObjects (\x -> case x of Affected.TheseObjects y -> Just y; _ -> Nothing),
          Arm.payload "Matching" filterCodec Affected.Matching (\x -> case x of Affected.Matching y -> Just y; _ -> Nothing),
          Arm.payload "MatchingAnywhere" filterCodec Affected.MatchingAnywhere (\x -> case x of Affected.MatchingAnywhere y -> Just y; _ -> Nothing),
          Arm.payload "MatchingOffBattlefield" filterCodec Affected.MatchingOffBattlefield (\x -> case x of Affected.MatchingOffBattlefield y -> Just y; _ -> Nothing),
          Arm.nullary "Attached" Affected.Attached,
          Arm.payload "AttachedPlayerControls" filterCodec Affected.AttachedPlayerControls (\x -> case x of Affected.AttachedPlayerControls y -> Just y; _ -> Nothing),
          Arm.payload "PlayedThisWay" Duration.codec Affected.PlayedThisWay (\x -> case x of Affected.PlayedThisWay y -> Just y; _ -> Nothing)
        ]

tagOf :: Affected.Affected -> String
tagOf x = case x of
  Affected.TheseObjects {} -> "TheseObjects"
  Affected.Matching {} -> "Matching"
  Affected.MatchingAnywhere {} -> "MatchingAnywhere"
  Affected.MatchingOffBattlefield {} -> "MatchingOffBattlefield"
  Affected.Attached {} -> "Attached"
  Affected.AttachedPlayerControls {} -> "AttachedPlayerControls"
  Affected.PlayedThisWay {} -> "PlayedThisWay"
