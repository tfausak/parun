{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AttackerTrigger where

import qualified Parun.Codec.AttackCompany as AttackCompany
import qualified Parun.Codec.AttackerTarget as AttackerTarget
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.TriggerFrequency as TriggerFrequency
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AttackCompany as AttackCompanyType
import qualified Parun.Types.AttackerTarget as AttackerTargetType
import qualified Parun.Types.AttackerTrigger as AttackerTrigger
import qualified Parun.Types.Filter as FilterType
import qualified Parun.Types.TriggerFrequency as TriggerFrequencyType

-- | A bare object keyed by the record's field names. Every key has a default,
-- so the source's own "whenever this creature attacks" writes none.
codec :: Codec.Codec AttackerTrigger.AttackerTrigger
codec = Fields.object $ do
  creature <- Fields.defaulted "creature" FilterType.IsSource (Filter.codec Keyword.codec) AttackerTrigger.creature
  target <- Fields.defaulted "target" AttackerTargetType.AnyTarget AttackerTarget.codec AttackerTrigger.target
  company <- Fields.defaulted "company" AttackCompanyType.AnyCompany AttackCompany.codec AttackerTrigger.company
  frequency <- Fields.defaulted "frequency" TriggerFrequencyType.EveryTime TriggerFrequency.codec AttackerTrigger.frequency
  while_ <- Fields.defaulted "while" Nothing (Common.maybe Condition.codec) AttackerTrigger.while
  pure
    AttackerTrigger.MkAttackerTrigger
      { AttackerTrigger.creature = creature,
        AttackerTrigger.target = target,
        AttackerTrigger.company = company,
        AttackerTrigger.frequency = frequency,
        AttackerTrigger.while = while_
      }
