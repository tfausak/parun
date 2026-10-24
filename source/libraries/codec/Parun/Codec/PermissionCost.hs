module Parun.Codec.PermissionCost where

import qualified Parun.Codec.ManaCost as ManaCost
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PermissionCost as PermissionCost

codec :: Codec.Codec PermissionCost.PermissionCost
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "InsteadOfManaCost" ManaCost.codec PermissionCost.InsteadOfManaCost (\x -> case x of PermissionCost.InsteadOfManaCost y -> Just y; _ -> Nothing),
      Arm.nullary "WaterbendManaValue" PermissionCost.WaterbendManaValue
    ]

tagOf :: PermissionCost.PermissionCost -> String
tagOf x = case x of
  PermissionCost.InsteadOfManaCost {} -> "InsteadOfManaCost"
  PermissionCost.WaterbendManaValue {} -> "WaterbendManaValue"
