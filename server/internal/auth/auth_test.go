package auth

import (
	"testing"
	"time"
)

func TestPasswordRoundTrip(t *testing.T) {
	hash, err := HashPassword("correct horse battery")
	if err != nil {
		t.Fatal(err)
	}
	if !VerifyPassword(hash, "correct horse battery") {
		t.Error("correct password rejected")
	}
	if VerifyPassword(hash, "wrong horse battery") {
		t.Error("wrong password accepted")
	}
}

func TestVerifyPasswordRejectsMalformedHashes(t *testing.T) {
	for _, encoded := range []string{"", "plain", "$argon2id$v=19$m=1,t=1,p=1$!!$!!", "$bcrypt$a$b$c$d", "unusable"} {
		if VerifyPassword(encoded, "anything") {
			t.Errorf("accepted %q", encoded)
		}
	}
}

func TestNormalizeEmail(t *testing.T) {
	got, err := NormalizeEmail("  Ana@Example.COM ")
	if err != nil || got != "ana@example.com" {
		t.Errorf("got %q, %v", got, err)
	}
	for _, bad := range []string{"", "nope", "a b@example.com", "Ana <ana@example.com>"} {
		if _, err := NormalizeEmail(bad); err == nil {
			t.Errorf("accepted %q", bad)
		}
	}
}

func TestValidatePassword(t *testing.T) {
	if ValidatePassword("short") == nil {
		t.Error("short password accepted")
	}
	if err := ValidatePassword("twelve chars"); err != nil {
		t.Error(err)
	}
}

func TestLimiter(t *testing.T) {
	now := time.Unix(1000, 0)
	l := NewLimiter(2, time.Minute)
	l.now = func() time.Time { return now }

	l.Fail("a")
	if !l.Allowed("a") {
		t.Error("blocked before the limit")
	}
	l.Fail("a")
	if l.Allowed("a") {
		t.Error("allowed over the limit")
	}
	if !l.Allowed("b") {
		t.Error("keys must be independent")
	}
	now = now.Add(time.Minute)
	if !l.Allowed("a") {
		t.Error("still blocked after the window")
	}
	l.Fail("a")
	l.Reset("a")
	l.Fail("a")
	if !l.Allowed("a") {
		t.Error("reset did not clear failures")
	}
}

func TestTokenHashIsStable(t *testing.T) {
	token, hash, err := NewToken()
	if err != nil {
		t.Fatal(err)
	}
	if string(HashToken(token)) != string(hash) {
		t.Error("hash mismatch")
	}
}
