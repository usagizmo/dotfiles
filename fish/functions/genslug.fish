function genslug -d "friendly slug（adjective-noun）を生成してクリップボードへコピー"
    set -l adjectives \
        agile alert ancient bright brisk broad calm candid cedar clear clever close cool crisp curious dawn \
        deep distant downy early earnest easy even faint fair faithful far fine fleet fluid fond fresh \
        gentle genuine glad gold golden graceful gray green happy hazy high honest humble keen kind lasting \
        level light lithe lively lucid luminous mellow mild misty modest nimble noble open patient peaceful \
        plain plush quick quiet radiant rapid rare ready rich rising rustic sage serene silent silver \
        simple sincere slow smooth soft spare sparse spry starlit steady still storied subtle sunny supple \
        swift tender thoughtful tidy timeless tranquil true vibrant vivid warm wary wide wise
    set -l nouns \
        almanac arbor archive atlas aurora birch bramble brook burrow canon cascade cedar clover codex \
        comet copse cosmos current dell den dusk ember fern field folio forest garden glade gleam glen \
        grove haven hearth hedge hedgerow hollow island juniper knoll lake ledger lookout lore lumen maple \
        meadow meteor nova oak orchard overlook pasture path peak pine pond prairie primer range reserve \
        ridge river sanctuary scroll shelter slope spinney sprig spring star stream thicket tome trail \
        twilight valley vantage verse vista warren willow zenith

    set -l result $adjectives[(random 1 (count $adjectives))]-$nouns[(random 1 (count $nouns))]
    echo -n $result | pbcopy
    echo "📋 $result"
end
