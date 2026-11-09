package words

import "testing"

func TestEveryLanguageHasEveryText(t *testing.T) {
	for language, own := range texts {
		for key := range texts["en"] {
			if own[key] == "" {
				t.Errorf("%s has no %s", language, key)
			}
		}
	}
	if got := Say("hr", SharedSubject, "More"); got != "S vama je podijeljen album: More" {
		t.Fatal(got)
	}
	if got := Say("xx", TestSubject); got != "Mediarr test message" {
		t.Fatal(got)
	}
}
