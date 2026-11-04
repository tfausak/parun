module Parun.Codec.CompanyCount where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CompanyCount as CompanyCount

codec :: Codec.Codec CompanyCount.CompanyCount
codec =
  Arm.tagged
    tag
    [ Arm.payload "AtLeastOthers" Common.natural CompanyCount.AtLeastOthers (\x -> case x of CompanyCount.AtLeastOthers y -> Just y; _ -> Nothing),
      Arm.nullary "NoOthers" CompanyCount.NoOthers
    ]

tag :: CompanyCount.CompanyCount -> String
tag x = case x of
  CompanyCount.AtLeastOthers {} -> "AtLeastOthers"
  CompanyCount.NoOthers -> "NoOthers"
