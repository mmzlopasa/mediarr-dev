package jobs

import (
	"context"
	"fmt"
	"log/slog"
	"math/bits"
	"strconv"

	"github.com/jackc/pgx/v5/pgtype"

	"github.com/mediarr-app/mediarr/server/db"
)

// videoFrames are where in a video its fingerprint is taken, as parts of its length.
var videoFrames = [...]float64{0.10, 0.35, 0.60, 0.85}

// sameVideoLength is how much two copies of one video may differ in length, in milliseconds.
const sameVideoLength = 1000

// videoFingerprint hashes four frames of a video, the same way as a picture.
func videoFingerprint(ctx context.Context, path string, durationMs int64) ([]int64, error) {
	out := make([]int64, 0, len(videoFrames))
	side := fmt.Sprintf("scale=%d:%d,format=gray", fingerprintSide, fingerprintSide)
	for _, at := range videoFrames {
		seconds := strconv.FormatFloat(float64(durationMs)*at/1000, 'f', 3, 64)
		frame, err := runTool(ctx, "ffmpeg", "-nostdin", "-v", "error", "-ss", seconds, "-i", path,
			"-vf", side, "-frames:v", "1", "-f", "rawvideo", "-")
		if err != nil {
			return nil, err
		}
		if len(frame) != fingerprintSide*fingerprintSide {
			return nil, fmt.Errorf("expected %d bytes, got %d", fingerprintSide*fingerprintSide, len(frame))
		}
		out = append(out, int64(PerceptualHash(frame, fingerprintSide))) //nolint:gosec // Stored bit for bit.
	}
	return out, nil
}

// SameVideo says whether two fingerprinted videos are one video: as long, and every frame alike.
func SameVideo(a, b []int64, lengthA, lengthB int64) bool {
	if len(a) != len(videoFrames) || len(b) != len(videoFrames) {
		return false
	}
	if diff := lengthA - lengthB; diff > sameVideoLength || diff < -sameVideoLength {
		return false
	}
	for i := range a {
		if bits.OnesCount64(uint64(a[i]^b[i])) > maxHashDistance { //nolint:gosec // Bits, not a number.
			return false
		}
	}
	return true
}

// organizeVideos fingerprints new videos and proposes the ones that are the same as another.
func organizeVideos(ctx context.Context, q *db.Queries) (int, error) {
	rows, err := q.ListUnfingerprintedVideos(ctx, organizeBatch)
	if err != nil || len(rows) == 0 {
		return 0, err
	}
	for i := range rows {
		row := &rows[i]
		hash := []int64{}
		if row.DurationMs.Valid && row.DurationMs.Int64 > 0 {
			if found, err := videoFingerprint(ctx, row.OriginalPath, row.DurationMs.Int64); err == nil {
				hash = found
			} else {
				slog.Warn("a video could not be compared", "asset", uuidString(row.ID), "error", err)
			}
		}
		if err := q.SetVideoFingerprint(ctx, db.SetVideoFingerprintParams{ID: row.ID, Vhash: hash}); err != nil {
			return 0, err
		}
		if len(hash) == 0 {
			continue
		}
		if err := compareVideo(ctx, q, row.UserID, row.ID, hash, row.DurationMs.Int64); err != nil {
			return 0, err
		}
	}
	return len(rows), nil
}

func compareVideo(ctx context.Context, q *db.Queries, user, id pgtype.UUID, hash []int64, length int64) error {
	others, err := q.ListVideoHashes(ctx, user)
	if err != nil {
		return err
	}
	for i := range others {
		other := &others[i]
		if other.ID == id || !SameVideo(hash, other.Vhash, length, other.DurationMs.Int64) {
			continue
		}
		if err := q.AddSimilarPair(ctx, db.AddSimilarPairParams{X: id, Y: other.ID, UserID: user}); err != nil {
			return err
		}
	}
	return nil
}
