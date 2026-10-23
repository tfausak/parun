# Reduces MTGJSON's AtomicCards.json to what `pawl ingest` reads (#9): every
# single-faced card as a record it may build, with the sets it was printed in
# for `pawl translate --set`, and every face's Oracle text by card and face
# name, which both stamp on the cards they write. Run as
#   jq -f script/ingest/candidates.jq _scratch/AtomicCards.json > _scratch/candidates.json
{
  version: .meta.version,
  cards: [
    .data[]
    | select(length == 1)
    | .[0]
    | select(.layout == "normal" and (.isFunny // false) == false)
    | {name, manaCost, colorIndicator, supertypes, types, subtypes, power, toughness, text, printings}
  ],
  texts: [.data | to_entries[] | .key as $card | .value[] | {card: $card, name: (.faceName // .name), text: (.text // "")}] | unique
}
