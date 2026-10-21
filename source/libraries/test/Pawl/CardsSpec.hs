-- Covers data/cards/*.json and the file-naming rule, Pawl.Registry.filedAs and
-- Pawl.Registry.cardPath -- through which it reaches Pawl.Slug.fromText, whose
-- own spec is Pawl.SlugSpec.
module Pawl.CardsSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.IO.Class as MonadIO
import qualified Data.ByteString as ByteString
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Pawl.Codec.Card as Card
import qualified Pawl.Codec.Printing as Printing
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonSchema.Define as Define
import qualified Pawl.JsonSchema.Validate as Validate
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Printing as Printing

spec :: (MonadIO.MonadIO n) => Spec.Spec IO n -> n ()
spec s = Spec.describe s "Pawl.Cards" $ do
  -- Listed, not parsed: each case reads its own file, so building the test
  -- tree decodes nothing and a narrow -p pays for no corpus parse.
  root <- MonadIO.liftIO Registry.defaultRoot
  paths <- MonadIO.liftIO (Registry.listRoot root)

  -- Rendered AND indexed once for the whole corpus rather than once per file.
  -- Validate.prepare walks every $defs entry, which is the expensive half of a
  -- validation and does not depend on the card; doing it per file put this
  -- case within a fifth of a second of the suite's five-second budget.
  let schema = Validate.prepare (Define.run (Codec.schema Card.codec))

  Monad.forM_ paths $ \path ->
    Spec.it s (reverse (drop (length ".json") (takeWhile (/= '/') (reverse path)))) $ do
      checkFile s root schema path

checkFile :: Spec.Spec IO n -> FilePath -> Validate.Document -> FilePath -> IO ()
checkFile s root schema path = do
  -- Read as bytes and decoded as UTF-8 explicitly, for the reason
  -- Pawl.Registry.parseCard is: Data.Text.IO.readFile decodes using the locale
  -- encoding, which is ASCII under LC_ALL=C, so this would otherwise die on
  -- khabal-ghoul.json's "á". Not parseCard alone -- this case wants the decoded
  -- JSON value to compare against, not only a Card.
  bytes <- ByteString.readFile path
  case Encoding.decodeUtf8' bytes of
    Left err -> Spec.assertFailure s (path <> ": not valid UTF-8: " <> show err)
    Right contents ->
      case Common.parse contents of
        Left err -> Spec.assertFailure s (path <> ": " <> Text.unpack err)
        Right value -> do
          -- Every committed file matches the schema the card codec publishes.
          -- Asserted BEFORE the decode and re-encoding below, which would
          -- otherwise absorb a schema defect and report itself instead.
          -- Card.codec rather than Printing.codec because Registry.parseCard is
          -- what reads these files and it decodes a Card; the two write the
          -- same wire.
          Spec.assertEqWith s (path <> ": schema") (Validate.validateWith schema value) []
          case Registry.parseCard bytes of
            Left err -> Spec.assertFailure s (path <> ": " <> Text.unpack err)
            Right card -> do
              let p = Printing.ofCard card
              -- The file lives where Registry.filedAs says a card with these
              -- faces is filed.
              Spec.assertEqWith s (path <> ": filed as") path (Registry.cardPath root (Registry.filedAs card))
              -- The loader reads everything the file says and invents nothing:
              -- re-encoding the loaded printing reproduces the file's meaning. Compared
              -- up to key order and whitespace, because JSON objects are unordered and
              -- formatting is not part of the contract. The corpus is committed
              -- pretty-printed (`jq -S .`) while Common.render emits compact output, so
              -- this can never quietly regress into a byte comparison: every file would
              -- fail at once.
              Spec.assertEqWith s path (Common.sortKeys (Codec.encode Printing.codec p)) (Common.sortKeys value)
