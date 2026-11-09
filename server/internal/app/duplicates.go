package app

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"path/filepath"
	"regexp"
	"slices"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/mediarr-app/mediarr/server/db"
	"github.com/mediarr-app/mediarr/server/internal/api"
	"github.com/mediarr-app/mediarr/server/internal/jobs"
)

const (
	maxDuplicateGroups = 100
	maxChosenGroups    = 100
)

// resavedName is how messaging apps name the copies they save again, smaller than the original.
var resavedName = regexp.MustCompile(`(?i)(^(IMG|VID)-\d{8}-WA\d+|whatsapp|telegram|^received_\d+|^FB_IMG_|messenger|^signal-\d{4}-\d{2}-\d{2})`)

// isOriginal is a camera's own format: a RAW or what a phone takes, HEIC.
func isOriginal(name string) bool {
	switch strings.ToLower(filepath.Ext(name)) {
	case ".heic", ".heif":
		return true
	}
	return jobs.IsRaw(name)
}

// shotFacts is what the proposal weighs, read from one photo of a group.
type shotFacts struct {
	row      *db.ListSimilarItemsRow
	original bool
	resaved  bool
}

func (f *shotFacts) format() int {
	switch {
	case f.original:
		return 2
	case f.resaved:
		return 0
	}
	return 1
}

func (f *shotFacts) pixels() int64 { return int64(f.row.Width.Int32) * int64(f.row.Height.Int32) }

func (f *shotFacts) known() int {
	count := 0
	for _, has := range []bool{f.row.HasDate, f.row.HasLocation, f.row.HasCaption} {
		if has {
			count++
		}
	}
	return count
}

// better proposes which of two to keep: a favorite, then the camera's own format over a copy an app
// saved again, then more pixels, then more that is known about it, then more bytes, then sharpness.
func better(a, b *shotFacts) bool {
	switch {
	case a.row.IsFavorite != b.row.IsFavorite:
		return a.row.IsFavorite
	case a.format() != b.format():
		return a.format() > b.format()
	case a.pixels() != b.pixels():
		return a.pixels() > b.pixels()
	case a.known() != b.known():
		return a.known() > b.known()
	case a.row.SizeBytes != b.row.SizeBytes:
		return a.row.SizeBytes > b.row.SizeBytes
	}
	return a.row.Sharpness.Float32 > b.row.Sharpness.Float32
}

// groupFacts reads what the proposal needs. A photo without a camera in a group where another has
// one was saved again by something.
func groupFacts(rows []*db.ListSimilarItemsRow) []shotFacts {
	anyCamera := slices.ContainsFunc(rows, func(row *db.ListSimilarItemsRow) bool { return row.CameraMake != "" })
	out := make([]shotFacts, len(rows))
	for i, row := range rows {
		original := isOriginal(row.OriginalName)
		out[i] = shotFacts{
			row: row, original: original,
			resaved: !original && (resavedName.MatchString(row.OriginalName) || (anyCamera && row.CameraMake == "")),
		}
	}
	return out
}

func keepOf(facts []shotFacts) int {
	best := 0
	for i := range facts[1:] {
		if better(&facts[i+1], &facts[best]) {
			best = i + 1
		}
	}
	return best
}

// isExact is the same file, or the same picture in the same size.
func isExact(rows []*db.ListSimilarItemsRow) bool {
	first := rows[0]
	sameFile, samePicture := true, first.Phash.Valid
	for _, row := range rows[1:] {
		sameFile = sameFile && bytes.Equal(row.Checksum, first.Checksum)
		samePicture = samePicture && row.Phash == first.Phash && row.Width == first.Width && row.Height == first.Height
	}
	return sameFile || samePicture
}

type duplicatePlan struct {
	keep  pgtype.UUID
	trash []pgtype.UUID
	exact bool
	freed int64
	group api.DuplicateGroup
}

// duplicatePlans are all of a person's groups, newest first, each with its proposal.
func (s *apiServer) duplicatePlans(ctx context.Context, user pgtype.UUID) ([]duplicatePlan, error) {
	rows, err := s.queries.ListSimilarPairs(ctx, user)
	if err != nil {
		return nil, err
	}
	pairs := make([][2]pgtype.UUID, len(rows))
	for i := range rows {
		pairs[i] = [2]pgtype.UUID{rows[i].AID, rows[i].BID}
	}
	groups := jobs.GroupPairs(pairs)
	ids := []pgtype.UUID{}
	for _, group := range groups {
		ids = append(ids, group...)
	}
	items, err := s.queries.ListSimilarItems(ctx, db.ListSimilarItemsParams{Column1: ids, UserID: user})
	if err != nil {
		return nil, err
	}
	byID := make(map[pgtype.UUID]*db.ListSimilarItemsRow, len(items))
	for i := range items {
		byID[items[i].ID] = &items[i]
	}
	plans := make([]duplicatePlan, 0, len(groups))
	newest := make([]int64, 0, len(groups))
	for _, group := range groups {
		rows := make([]*db.ListSimilarItemsRow, 0, len(group))
		for _, id := range group {
			if row := byID[id]; row != nil {
				rows = append(rows, row)
			}
		}
		if len(rows) < 2 {
			continue
		}
		plan, latest := planGroup(rows)
		plans = append(plans, plan)
		newest = append(newest, latest)
	}
	order := make([]int, len(plans))
	for i := range order {
		order[i] = i
	}
	slices.SortStableFunc(order, func(a, b int) int { return int(max(min(newest[b]-newest[a], 1), -1)) })
	sorted := make([]duplicatePlan, len(plans))
	for i, at := range order {
		sorted[i] = plans[at]
	}
	return sorted, nil
}

func planGroup(rows []*db.ListSimilarItemsRow) (duplicatePlan, int64) {
	facts := groupFacts(rows)
	keep := keepOf(facts)
	plan := duplicatePlan{keep: rows[keep].ID, exact: isExact(rows)}
	items := make([]api.DuplicateItem, len(rows))
	latest := int64(0)
	for i, row := range rows {
		latest = max(latest, row.LocalAt.Time.Unix())
		if i != keep {
			plan.trash = append(plan.trash, row.ID)
			plan.freed += row.SizeBytes
		}
		items[i] = api.DuplicateItem{
			Id: row.ID.Bytes, OriginalName: row.OriginalName, SizeBytes: row.SizeBytes,
			Width: optional(int(row.Width.Int32), row.Width.Valid), Height: optional(int(row.Height.Int32), row.Height.Valid),
			Ratio: ratioOf(row.AspectRatio, row.Width, row.Height), LocalAt: row.LocalAt.Time.Format(localTimeLayout),
			Favorite: row.IsFavorite, Original: facts[i].original, Resaved: facts[i].resaved,
			HasDate: row.HasDate, HasLocation: row.HasLocation, HasCaption: row.HasCaption,
		}
	}
	plan.group = api.DuplicateGroup{KeepId: openapi_types.UUID(plan.keep.Bytes), Exact: plan.exact, FreedBytes: plan.freed, Items: items}
	return plan, latest
}

func (s *apiServer) ListDuplicates(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	ctx := r.Context()
	pending, err := s.queries.CountUnorganized(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	plans, err := s.duplicatePlans(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	out := api.Duplicates{Total: len(plans), Pending: int(pending), Groups: make([]api.DuplicateGroup, 0, min(len(plans), maxDuplicateGroups))}
	exact := 0
	for i := range plans {
		if plans[i].exact {
			exact++
		}
		if i < maxDuplicateGroups {
			out.Groups = append(out.Groups, plans[i].group)
		}
	}
	out.ExactTotal = &exact
	progress, running, err := jobs.LoadResolveProgress(ctx, s.queries, uuid.UUID(user.ID.Bytes))
	if err != nil {
		internalError(w, r, err)
		return
	}
	if running {
		out.Resolving = &api.ResolveProgress{Done: progress.Done, Total: progress.Total}
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *apiServer) DismissDuplicates(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.AssetIds
	if !readJSON(w, r, &body) {
		return
	}
	ids := make([]pgtype.UUID, len(body.Ids))
	for i, id := range body.Ids {
		ids[i] = pgUUID(id)
	}
	if err := s.queries.DismissSimilar(r.Context(), db.DismissSimilarParams{UserID: user.ID, Column2: ids}); err != nil {
		internalError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// chosenGroups checks the groups a person chose: one to keep, others to let go, none twice.
func chosenGroups(choices []api.DuplicateChoice) ([]jobs.DuplicateChoice, string) {
	if len(choices) == 0 || len(choices) > maxChosenGroups {
		return nil, "choose between 1 and 100 groups"
	}
	seen := map[uuid.UUID]bool{}
	out := make([]jobs.DuplicateChoice, len(choices))
	for i, choice := range choices {
		ids := append([]uuid.UUID{choice.KeepId}, choice.TrashIds...)
		for _, id := range ids {
			if seen[id] {
				return nil, "a photo is in two places of the choice"
			}
			seen[id] = true
		}
		out[i] = jobs.DuplicateChoice{Keep: choice.KeepId, Trash: choice.TrashIds}
	}
	return out, ""
}

func (s *apiServer) ResolveDuplicates(w http.ResponseWriter, r *http.Request) {
	user := requireUser(w, r)
	if user == nil {
		return
	}
	var body api.DuplicateResolve
	if !readJSON(w, r, &body) {
		return
	}
	all := body.All != nil && *body.All
	dryRun := body.DryRun != nil && *body.DryRun
	if all {
		s.resolveAll(w, r, user, body.ExactOnly != nil && *body.ExactOnly, dryRun)
		return
	}
	if body.Groups == nil {
		writeError(w, http.StatusBadRequest, "choose groups, or all of them")
		return
	}
	choices, problem := chosenGroups(*body.Groups)
	if problem != "" {
		writeError(w, http.StatusBadRequest, problem)
		return
	}
	result, err := s.resolveNow(r.Context(), user.ID, choices, dryRun)
	if errors.Is(err, jobs.ErrNothingToKeep) {
		writeError(w, http.StatusBadRequest, "a photo to keep is not yours or is in the trash")
		return
	}
	if err != nil {
		internalError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func toPg(ids []uuid.UUID) []pgtype.UUID {
	out := make([]pgtype.UUID, len(ids))
	for i, id := range ids {
		out[i] = pgtype.UUID{Bytes: id, Valid: true}
	}
	return out
}

// resolveNow merges a few groups while the person waits, all or nothing.
func (s *apiServer) resolveNow(ctx context.Context, user pgtype.UUID, choices []jobs.DuplicateChoice, dryRun bool) (api.DuplicateResolveResult, error) {
	result := api.DuplicateResolveResult{Groups: len(choices)}
	if dryRun {
		for _, choice := range choices {
			facts, err := s.queries.MergeFacts(ctx, db.MergeFactsParams{UserID: user, Column2: toPg(choice.Trash)})
			if err != nil {
				return result, err
			}
			for i := range facts {
				result.Trashed++
				result.FreedBytes += facts[i].SizeBytes
			}
		}
		return result, nil
	}
	err := pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		q := s.queries.WithTx(tx)
		for _, choice := range choices {
			merged, err := jobs.MergeDuplicate(ctx, q, user, pgtype.UUID{Bytes: choice.Keep, Valid: true}, toPg(choice.Trash))
			if err != nil {
				return err
			}
			result.Trashed += int(merged.Trashed)
			result.FreedBytes += merged.FreedBytes
			if merged.Facts {
				if _, err := s.Inserter.InsertTx(ctx, tx, jobs.SidecarArgs{AssetID: choice.Keep}, nil); err != nil {
					return err
				}
			}
		}
		return nil
	})
	return result, err
}

// resolveAll takes every proposal, or every proposal for the same file or picture, in the background.
func (s *apiServer) resolveAll(w http.ResponseWriter, r *http.Request, user *db.User, exactOnly, dryRun bool) {
	ctx := r.Context()
	owner := uuid.UUID(user.ID.Bytes)
	if _, running, err := jobs.LoadResolveProgress(ctx, s.queries, owner); err != nil {
		internalError(w, r, err)
		return
	} else if running && !dryRun {
		writeError(w, http.StatusConflict, "the duplicates are already being resolved")
		return
	}
	plans, err := s.duplicatePlans(ctx, user.ID)
	if err != nil {
		internalError(w, r, err)
		return
	}
	result := api.DuplicateResolveResult{}
	choices := []jobs.DuplicateChoice{}
	for i := range plans {
		plan := &plans[i]
		if exactOnly && !plan.exact {
			continue
		}
		trash := make([]uuid.UUID, len(plan.trash))
		for j, id := range plan.trash {
			trash[j] = id.Bytes
		}
		choices = append(choices, jobs.DuplicateChoice{Keep: plan.keep.Bytes, Trash: trash})
		result.Groups++
		result.Trashed += len(plan.trash)
		result.FreedBytes += plan.freed
	}
	if dryRun || len(choices) == 0 {
		writeJSON(w, http.StatusOK, result)
		return
	}
	err = pgx.BeginFunc(ctx, s.Pool, func(tx pgx.Tx) error {
		if err := jobs.SaveResolveProgress(ctx, s.queries.WithTx(tx), owner, jobs.ResolveProgress{Total: len(choices)}); err != nil {
			return err
		}
		_, err := s.Inserter.InsertTx(ctx, tx, jobs.ResolveDuplicatesArgs{UserID: owner, Groups: choices}, nil)
		return err
	})
	if err != nil {
		internalError(w, r, err)
		return
	}
	result.Background = true
	writeJSON(w, http.StatusAccepted, result)
}
