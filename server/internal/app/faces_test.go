package app

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
	"github.com/mediarr-app/mediarr/server/internal/ml"
)

func assetFaces(t *testing.T, c *client, asset string) []api.AssetFace {
	t.Helper()
	resp, body := c.get("/api/assets/" + asset + "/faces")
	expect(t, resp, body, http.StatusOK)
	return decode[api.AssetFaces](t, body).Faces
}

func analyzeAgain(t *testing.T, s *stack, url, id string) {
	t.Helper()
	var asset pgtype.UUID
	if err := asset.Scan(id); err != nil {
		t.Fatal(err)
	}
	if err := jobs.AnalyzeAsset(context.Background(), s.pool, db.New(s.pool), ml.New(url), asset); err != nil {
		t.Fatal(err)
	}
}

func TestACorrectedFaceStaysCorrectedAfterAnalysis(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	c := s.admin()
	photo := s.analyzed(t, c, service, "1.jpg", "2024-01-01T10:00:00Z", "ana")
	faces := assetFaces(t, c, photo)
	if len(faces) != 1 {
		t.Fatalf("faces: %+v", faces)
	}
	path := "/api/faces/" + faces[0].Id.String()

	empty := ""
	resp, body := c.send(http.MethodPut, path, api.FaceAssign{Name: &empty})
	expect(t, resp, body, http.StatusBadRequest)

	name := "Teta Mara"
	resp, body = c.send(http.MethodPut, path, api.FaceAssign{Name: &name})
	expect(t, resp, body, http.StatusNoContent)
	analyzeAgain(t, s, service.URL, photo)
	faces = assetFaces(t, c, photo)
	if len(faces) != 1 || faces[0].Person == nil || faces[0].Person.Name != name {
		t.Fatalf("after analysing again: %+v", faces)
	}

	// The newest answer stands, not the first.
	other := "Stric Ante"
	resp, body = c.send(http.MethodPut, "/api/faces/"+faces[0].Id.String(), api.FaceAssign{Name: &other})
	expect(t, resp, body, http.StatusNoContent)
	analyzeAgain(t, s, service.URL, photo)
	faces = assetFaces(t, c, photo)
	if len(faces) != 1 || faces[0].Person.Name != other {
		t.Fatalf("after a second answer: %+v", faces)
	}

	resp, body = c.send(http.MethodDelete, "/api/faces/"+faces[0].Id.String(), nil)
	expect(t, resp, body, http.StatusNoContent)
	analyzeAgain(t, s, service.URL, photo)
	if faces := assetFaces(t, c, photo); len(faces) != 0 {
		t.Fatalf("a removed face came back: %+v", faces)
	}
}

func TestSomeoneElsesFaceCannotBeTouched(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	owner := s.admin()
	stranger := s.user(owner, "stranger@example.com")
	photo := s.analyzed(t, owner, service, "1.jpg", "2024-01-01T10:00:00Z", "ana")
	mine := s.analyzed(t, stranger, service, "2.jpg", "2024-01-01T10:00:00Z", "ana")
	face := assetFaces(t, owner, photo)[0]
	path := "/api/faces/" + face.Id.String()

	resp, body := stranger.get("/api/assets/" + photo + "/faces")
	expect(t, resp, body, http.StatusNotFound)
	name := "Nobody"
	resp, body = stranger.send(http.MethodPut, path, api.FaceAssign{Name: &name})
	expect(t, resp, body, http.StatusNotFound)
	resp, body = stranger.send(http.MethodDelete, path, nil)
	expect(t, resp, body, http.StatusNotFound)
	// Nor can a face be given to someone else's person.
	theirs := assetFaces(t, stranger, mine)[0]
	resp, body = stranger.send(http.MethodPut, "/api/faces/"+theirs.Id.String(), api.FaceAssign{PersonId: &face.Person.Id})
	expect(t, resp, body, http.StatusNotFound)
}

func TestADateOfBirthIsSavedAndRemoved(t *testing.T) {
	service := fakeML(t)
	s := newStack(t)
	c := s.admin()
	s.analyzed(t, c, service, "1.jpg", "2024-01-01T10:00:00Z", "ana")
	s.analyzed(t, c, service, "2.jpg", "2024-01-02T10:00:00Z", "ana")
	person := got0(t, peopleNamed(t, c))
	date := "1990-05-17"
	resp, body := c.send(http.MethodPatch, "/api/people/"+person, api.PersonUpdate{BirthDate: &date})
	expect(t, resp, body, http.StatusNoContent)
	if got := peopleNamed(t, c)[0].BirthDate; got == nil || *got != date {
		t.Fatalf("saved: %v", got)
	}
	future := time.Now().AddDate(1, 0, 0).Format(time.DateOnly)
	resp, body = c.send(http.MethodPatch, "/api/people/"+person, api.PersonUpdate{BirthDate: &future})
	expect(t, resp, body, http.StatusBadRequest)
	none := ""
	resp, body = c.send(http.MethodPatch, "/api/people/"+person, api.PersonUpdate{BirthDate: &none})
	expect(t, resp, body, http.StatusNoContent)
	if got := peopleNamed(t, c)[0].BirthDate; got != nil {
		t.Fatalf("removed: %v", *got)
	}
}
