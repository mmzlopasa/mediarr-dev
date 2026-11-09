package app

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
)

func shot(name string, width, size int64, camera string) *db.ListSimilarItemsRow {
	return &db.ListSimilarItemsRow{
		OriginalName: name, Width: pgtype.Int4{Int32: int32(width), Valid: true}, Height: pgtype.Int4{Int32: int32(width), Valid: true},
		SizeBytes: size, CameraMake: camera,
	}
}

func TestTheProposalKeepsTheOriginalOverAnAppsCopy(t *testing.T) {
	heic := shot("IMG_0001.HEIC", 3000, 2_000_000, "Apple")
	whatsapp := shot("IMG-20240705-WA0003.jpg", 4000, 3_000_000, "")
	plain := shot("IMG_0001.jpg", 3000, 2_500_000, "Apple")
	facts := groupFacts([]*db.ListSimilarItemsRow{whatsapp, plain, heic})
	if !facts[0].resaved || facts[1].resaved || !facts[2].original {
		t.Fatalf("%+v", facts)
	}
	// The app's copy is larger here, yet the camera's own file is kept.
	if keep := keepOf(facts); keep != 2 {
		t.Fatalf("kept %d", keep)
	}
	// A favorite wins over everything.
	whatsapp.IsFavorite = true
	if keep := keepOf(groupFacts([]*db.ListSimilarItemsRow{whatsapp, plain, heic})); keep != 0 {
		t.Fatalf("kept %d", keep)
	}
	// Between equals, the one with more known about it: a place.
	a, b := shot("a.jpg", 3000, 100, "X"), shot("b.jpg", 3000, 100, "X")
	b.HasLocation = true
	if keep := keepOf(groupFacts([]*db.ListSimilarItemsRow{a, b})); keep != 1 {
		t.Fatalf("kept %d", keep)
	}
}

func (s *stack) exec(t *testing.T, sql string, args ...any) {
	t.Helper()
	if _, err := s.pool.Exec(context.Background(), sql, args...); err != nil {
		t.Fatal(err)
	}
}

func TestTheKeptPhotoGetsWhatItsCopiesHad(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	keep := c.newPhoto(t, "IMG_0001.HEIC", "2024-07-05T10:00:00Z")
	copied := c.newPhoto(t, "IMG-20240705-WA0003.jpg", "2024-07-05T10:00:00Z")
	stranger := s.user(c, "other@example.com").newPhoto(t, "theirs.jpg", "2024-07-05T10:00:00Z")
	album := c.newAlbum(map[string]any{"title": "Holiday"})
	resp, body := c.post("/api/albums/"+album+"/assets", map[string]any{"ids": []string{copied}})
	expect(t, resp, body, http.StatusOK)
	resp, body = c.post("/api/assets/tags", map[string]any{"ids": []string{copied}, "name": "beach"})
	expect(t, resp, body, http.StatusOK)
	s.exec(t, `UPDATE assets SET is_favorite = true, caption = 'At the lake', rating = 4 WHERE id = $1`, copied)
	s.exec(t, `UPDATE albums SET cover_asset_id = $2 WHERE id = $1`, album, copied)
	s.placeAt(t, copied, 45.815, 15.9819)
	var person string
	if err := s.pool.QueryRow(context.Background(), `INSERT INTO people (user_id, name) SELECT user_id, 'Ana' FROM assets WHERE id = $1 RETURNING id`, copied).Scan(&person); err != nil {
		t.Fatal(err)
	}
	s.exec(t, `INSERT INTO faces (asset_id, user_id, person_id, x1, y1, x2, y2, score, embedding)
		SELECT id, user_id, $2, 10, 10, 50, 50, 0.9, array_fill(0.1, ARRAY[512])::real[]::vector FROM assets WHERE id = $1`, copied, person)

	// A preview counts without changing anything.
	choice := map[string]any{"groups": []map[string]any{{"keepId": keep, "trashIds": []string{copied}}}}
	resp, body = c.post("/api/duplicates/resolve", map[string]any{"groups": choice["groups"], "dryRun": true})
	expect(t, resp, body, http.StatusOK)
	if result := decode[api.DuplicateResolveResult](t, body); result.Trashed != 1 || result.FreedBytes == 0 {
		t.Fatalf("%s", body)
	}

	// Someone else's photo cannot be kept, nor sent to the trash.
	resp, body = c.post("/api/duplicates/resolve", map[string]any{"groups": []map[string]any{{"keepId": stranger, "trashIds": []string{keep}}}})
	expect(t, resp, body, http.StatusBadRequest)
	resp, body = c.post("/api/duplicates/resolve", map[string]any{"groups": []map[string]any{{"keepId": keep, "trashIds": []string{keep}}}})
	expect(t, resp, body, http.StatusBadRequest)

	resp, body = c.post("/api/duplicates/resolve", choice)
	expect(t, resp, body, http.StatusOK)
	if result := decode[api.DuplicateResolveResult](t, body); result.Trashed != 1 {
		t.Fatalf("%s", body)
	}
	var favorite bool
	var caption string
	var rating int
	var inAlbum, tagged, hinted int
	var cover string
	err := s.pool.QueryRow(context.Background(), `SELECT a.is_favorite, a.caption, a.rating,
		(SELECT count(*) FROM album_assets WHERE asset_id = a.id),
		(SELECT count(*) FROM asset_tags WHERE asset_id = a.id),
		(SELECT count(*) FROM face_hints WHERE asset_id = a.id AND person_id = $2),
		(SELECT cover_asset_id::text FROM albums WHERE id = $3)
		FROM assets a WHERE a.id = $1`, keep, person, album).Scan(&favorite, &caption, &rating, &inAlbum, &tagged, &hinted, &cover)
	if err != nil {
		t.Fatal(err)
	}
	if !favorite || caption != "At the lake" || rating != 4 || inAlbum != 1 || tagged != 1 || hinted != 1 || cover != keep {
		t.Fatalf("favorite %v, caption %q, rating %d, albums %d, tags %d, hints %d, cover %s", favorite, caption, rating, inAlbum, tagged, hinted, cover)
	}
	if loc := s.location(t, keep); loc != "45.8150,15.9819" {
		t.Fatalf("location %s", loc)
	}
	var deleted bool
	if err := s.pool.QueryRow(context.Background(), `SELECT deleted_at IS NOT NULL FROM assets WHERE id = $1`, copied).Scan(&deleted); err != nil || !deleted {
		t.Fatalf("the copy is not in the trash: %v", err)
	}
}

func TestAllDuplicatesAreResolvedInTheBackground(t *testing.T) {
	s := newStack(t)
	c := s.admin()
	for i, name := range []string{"a1.jpg", "a2.jpg", "b1.jpg", "b2.jpg"} {
		id := c.newPhoto(t, name, "2024-07-0"+string(rune('1'+i/2))+"T10:00:00Z")
		hash := int64(0b1111)
		if i >= 2 {
			hash = -1
		}
		// The second pair only looks alike: the sizes differ.
		size := 1000
		if i == 3 {
			size = 500
		}
		s.exec(t, `UPDATE assets SET phash = $2, width = $3, height = $3 WHERE id = $1`, id, hash, size)
	}
	s.organize(t)
	resp, body := c.get("/api/duplicates")
	expect(t, resp, body, http.StatusOK)
	found := decode[api.Duplicates](t, body)
	if found.Total != 2 || found.ExactTotal == nil || *found.ExactTotal != 1 {
		t.Fatalf("%s", body)
	}

	resp, body = c.post("/api/duplicates/resolve", map[string]any{"all": true, "exactOnly": true, "dryRun": true})
	expect(t, resp, body, http.StatusOK)
	if result := decode[api.DuplicateResolveResult](t, body); result.Groups != 1 || result.Trashed != 1 || result.Background {
		t.Fatalf("%s", body)
	}
	s.startWorker(t)
	resp, body = c.post("/api/duplicates/resolve", map[string]any{"all": true})
	expect(t, resp, body, http.StatusAccepted)
	if result := decode[api.DuplicateResolveResult](t, body); result.Groups != 2 || !result.Background {
		t.Fatalf("%s", body)
	}
	deadline := time.Now().Add(30 * time.Second)
	for {
		resp, body = c.get("/api/duplicates")
		expect(t, resp, body, http.StatusOK)
		if now := decode[api.Duplicates](t, body); now.Total == 0 && now.Resolving == nil {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("not resolved: %s", body)
		}
		time.Sleep(200 * time.Millisecond)
	}
	if items := len(timelineOf(t, c)); items != 2 {
		t.Fatalf("timeline: %d", items)
	}
}
