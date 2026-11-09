package jobs

import (
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

func dayAt(day string) time.Time {
	t, err := time.Parse(time.DateOnly, day)
	if err != nil {
		panic(err)
	}
	return t.Add(10 * time.Hour)
}

func photo(day, city string, lat, lon float64) *memoryAsset {
	return &memoryAsset{at: dayAt(day), city: city, hasGPS: true, lat: lat, lon: lon}
}

func TestHomeIsThePlaceWithTheMostPhotos(t *testing.T) {
	assets := []*memoryAsset{
		photo("2024-01-01", "Split", 43.5, 16.4), photo("2024-01-02", "Zagreb", 45.8, 16),
		photo("2024-01-03", "Zagreb", 45.8, 16),
	}
	if home := findHome(assets); home.name != "Zagreb" || !home.located {
		t.Fatalf("%+v", home)
	}
}

func TestATripEndsAtHomeAndAfterALongGap(t *testing.T) {
	home := homePlace{name: "Zagreb", lat: 45.8, lon: 16, located: true}
	away := func(day string) []*memoryAsset {
		out := []*memoryAsset{}
		for range 3 {
			out = append(out, photo(day, "Split", 43.5, 16.4))
		}
		return out
	}
	assets := append(away("2024-07-01"), away("2024-07-02")...)
	assets = append(assets, photo("2024-07-03", "Zagreb", 45.8, 16))
	assets = append(assets, away("2024-07-04")...)
	assets = append(assets, away("2024-07-05")...)
	assets = append(assets, away("2024-07-09")...) // Too long after, and a single day.
	trips := findTrips(assets, home)
	if len(trips) != 2 || !trips[0].to.Equal(dayAt("2024-07-02").Truncate(24*time.Hour)) {
		t.Fatalf("%+v", trips)
	}
}

func TestPickBestPrefersFavoritesAndSpreads(t *testing.T) {
	assets := []*memoryAsset{}
	for i := range 10 {
		a := photo("2023-01-01", "", 0, 0)
		a.id = pgtype.UUID{Bytes: [16]byte{byte(i)}, Valid: true}
		a.favorite = i == 9
		assets = append(assets, a)
	}
	got := pickBest(assets, 2, noBucket)
	if len(got) != 2 || (got[0].Bytes[0] != 9 && got[1].Bytes[0] != 9) {
		t.Fatalf("%v", got)
	}
}

func TestMonthBeforeStaysInItsMonth(t *testing.T) {
	if got := monthBefore(dayAt("2024-03-31")); got.Format(time.DateOnly) != "2024-02-29" {
		t.Fatal(got)
	}
}
