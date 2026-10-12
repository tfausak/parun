# Sorts every card in MTGJSON's AtomicCards.json into one bucket of how far
# pawl covers it (#5039). Run through script/census/census.sh, which supplies,
# each slurped,
#   $pool    the pool's card names, faces joined by " // " as MTGJSON keys them
#   $rules   docs/rules.txt, for the CR 701 and CR 702 keyword names
# A card's ring (docs/design.md section 6) is 2 for an un-card, 3 for one with
# no Vintage legality at all (digital-only), and 1 otherwise.
# A keyword-only card is one whose every line is a CR 702 keyword named as such,
# alone or followed by mana symbols or a number: slice A's and slice B's shape
# (#9, #5038). Landwalk and typecycling are named per type ("Forestwalk"), so
# their cards fall through to "other".
# A meld card is keyed by its front and the melded back ("Graf Rats // Chittering
# Host") but is its front alone in the pool, so the front face's name matches too.
# CENSUS_CARDS=1 in the environment prints one record per card instead.
# A keyword is known when some pool card carries it (MTGJSON's keywords, which
# name CR 701 actions and CR 702 abilities alike). An arm name in `pawl schema`
# is no witness: many actions are spelled otherwise there.

def squash: ascii_downcase | gsub("[^a-z]"; "");

# Rules text without reminder text (CR 207.2a), one ability per line, a line of
# comma-separated keywords split apart, as Pawl.Oracle.normalise does.
def lines: (. // "") | gsub("\\([^)]*\\)"; "") | split("\n") | map(split(", ")[]) | map(gsub("^\\s+|\\s+$"; "")) | map(select(. != ""));

$pool[0] as $pool
| ($rules | [scan("(?m)^70([12])\\.\\d+\\. ([^\\r\\n]+)$") | {(.[1] | squash): (if .[0] == "1" then "action" else "ability" end)}] | add) as $cr
| ($pool | map({(.): true}) | add) as $inPool
| .meta.version as $version
| def inPool: $inPool[.key] or $inPool[.value[0].faceName // ""];
  ([.data | to_entries[] | select(inPool) | .value[].keywords // [] | .[] | {(squash): true}] | add) as $known
| [ .data | to_entries[]
    | inPool as $pooled
    | .key as $name
    | .value as $sides
    | $sides[0] as $face
    | ($sides | map(.keywords // []) | add | unique) as $keywords
    | ($keywords | map(select($cr[squash] != null))) as $ruled
    | ($ruled | map(select($known[squash] | not))) as $unknown
    | ($sides | map(.text | lines) | add) as $text
    | ($keywords | map(ascii_downcase)) as $kw
    | ($text | map(capture("^(?<k>[A-Za-z' -]+?)(?:\\s+(?<p>(?:\\{[^}]+\\})+|\\d+|X))?$") // null)) as $parsed
    | ($parsed | all(. != null and (.k | ascii_downcase) as $k | ($kw | index([$k]) != null) and $cr[$k | squash] == "ability")) as $keywordOnly
    | { name: $name,
        ring: (if $face.isFunny then 2 elif ($face.legalities.vintage // null) == null then 3 else 1 end),
        bucket:
          (if $pooled then "pool"
           elif ($sides | length) == 1 and $face.layout == "normal" and $keywordOnly and ($parsed | all(.p == null)) then "nullary"
           elif ($sides | length) == 1 and $face.layout == "normal" and $keywordOnly then "payload"
           elif ($unknown | length) > 0 then "keyword"
           else "other" end),
        unknown: $unknown }
  ]
| if $ENV.CENSUS_CARDS then .[] else { version: $version,
    cards: length,
    rings: (group_by(.ring) | map({(.[0].ring | tostring): (group_by(.bucket) | map({(.[0].bucket): length}) | add)}) | add),
    blockers: (map(select(.ring == 1 and .bucket == "keyword") | .unknown[]) | group_by(.) | map({keyword: .[0], cards: length}) | sort_by(-.cards))
  } end
