package app

import (
	"fmt"
	"net/http"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const errBadPick = "a mark is 1 for picked, -1 for rejected or 0 for none"

func validPick(pick int) bool { return pick >= jobs.PickRejected && pick <= jobs.PickPicked }

// pickFilter reads the optional mark of a search or an album. Without one, nothing is filtered.
func pickFilter(pick *int) (pgtype.Int2, bool) {
	if pick == nil {
		return pgtype.Int2{}, true
	}
	if !validPick(*pick) {
		return pgtype.Int2{}, false
	}
	return pgtype.Int2{Int16: int16(*pick), Valid: true}, true //nolint:gosec // Checked above.
}

func pickIDs(w http.ResponseWriter, ids []uuid.UUID) ([]pgtype.UUID, bool) {
	if len(ids) == 0 || len(ids) > maxBulkIDs {
		writeError(w, http.StatusBadRequest, fmt.Sprintf("send between 1 and %d assets", maxBulkIDs))
		return nil, false
	}
	out := make([]pgtype.UUID, len(ids))
	for i, id := range ids {
		out[i] = pgUUID(id)
	}
	return out, true
}

// SetAssetPick marks the user's own photos. The file is not touched: the mark goes in the database
// and in the sidecar, which follows in a job of the same transaction.
func (s *apiServer) SetAssetPick(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.PickRequest
	if !readJSON(w, r, &body) {
		return
	}
	if !validPick(body.Pick) {
		writeError(w, http.StatusBadRequest, errBadPick)
		return
	}
	ids, ok := pickIDs(w, body.Ids)
	if !ok {
		return
	}
	ctx := r.Context()
	var changed []pgtype.UUID
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		var err error
		changed, err = s.queries.WithTx(tx).SetAssetPick(ctx, db.SetAssetPickParams{
			Pick: int16(body.Pick), UserID: user.ID, Ids: ids, //nolint:gosec // Checked above.
		})
		if err != nil {
			return err
		}
		for _, id := range changed {
			if _, err := s.Inserter.InsertTx(ctx, tx, jobs.SidecarArgs{AssetID: uuid.UUID(id.Bytes)}, nil); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, api.BulkResponse{Changed: int64(len(changed))})
}

// ReadAssetPicks tells the marks and stars of the user's own photos among those asked about.
func (s *apiServer) ReadAssetPicks(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.AssetIds
	if !readJSON(w, r, &body) {
		return
	}
	ids, ok := pickIDs(w, body.Ids)
	if !ok {
		return
	}
	rows, err := s.queries.ListAssetPicks(r.Context(), db.ListAssetPicksParams{UserID: user.ID, Ids: ids})
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.PickStates{Items: make([]api.PickState, len(rows))}
	for i, row := range rows {
		out.Items[i] = api.PickState{Id: row.ID.Bytes, Pick: int(row.Pick), Rating: int(row.Rating)}
	}
	writeJSON(w, http.StatusOK, out)
}
