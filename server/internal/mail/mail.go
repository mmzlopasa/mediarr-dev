// Package mail sends plain messages through the administrator's own SMTP server.
package mail

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"mime"
	"net"
	"net/smtp"
	"strconv"
	"strings"
	"time"
)

const sendTimeout = 20 * time.Second

// Security says how the connection is protected.
const (
	SecurityStartTLS = "starttls"
	SecurityTLS      = "tls"
	SecurityNone     = "none"
)

// Settings are what the administrator entered.
type Settings struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string
	Security string
}

func clean(field string) error {
	if strings.ContainsAny(field, "\r\n") {
		return errors.New("a line break is not allowed here")
	}
	return nil
}

// Send delivers one message. Line breaks in the headers are refused, as they could add others.
func Send(ctx context.Context, settings *Settings, to, subject, body string) error {
	for _, field := range []string{to, subject, settings.From} {
		if err := clean(field); err != nil {
			return err
		}
	}
	ctx, cancel := context.WithTimeout(ctx, sendTimeout)
	defer cancel()
	address := net.JoinHostPort(settings.Host, strconv.Itoa(settings.Port))
	dialer := &net.Dialer{}
	raw, err := dialer.DialContext(ctx, "tcp", address)
	if err != nil {
		return fmt.Errorf("connect: %w", err)
	}
	defer func() { _ = raw.Close() }()
	if deadline, ok := ctx.Deadline(); ok {
		if err := raw.SetDeadline(deadline); err != nil {
			return err
		}
	}
	config := &tls.Config{ServerName: settings.Host, MinVersion: tls.VersionTLS12}
	connection := raw
	if settings.Security == SecurityTLS {
		connection = tls.Client(raw, config)
	}
	client, err := smtp.NewClient(connection, settings.Host)
	if err != nil {
		return fmt.Errorf("start: %w", err)
	}
	defer func() { _ = client.Close() }()
	if settings.Security == SecurityStartTLS {
		if ok, _ := client.Extension("STARTTLS"); !ok {
			return errors.New("the mail server does not offer STARTTLS")
		}
		if err := client.StartTLS(config); err != nil {
			return fmt.Errorf("starttls: %w", err)
		}
	}
	if settings.Username != "" {
		// PlainAuth itself refuses to send a password over an open connection to another host.
		auth := smtp.PlainAuth("", settings.Username, settings.Password, settings.Host)
		if err := client.Auth(auth); err != nil {
			return fmt.Errorf("sign in: %w", err)
		}
	}
	if err := client.Mail(settings.From); err != nil {
		return fmt.Errorf("from: %w", err)
	}
	if err := client.Rcpt(to); err != nil {
		return fmt.Errorf("to: %w", err)
	}
	writer, err := client.Data()
	if err != nil {
		return err
	}
	message := "From: " + settings.From + "\r\nTo: " + to +
		"\r\nSubject: " + mime.QEncoding.Encode("utf-8", subject) +
		"\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n" +
		strings.ReplaceAll(body, "\n", "\r\n")
	if _, err := writer.Write([]byte(message)); err != nil {
		return err
	}
	if err := writer.Close(); err != nil {
		return err
	}
	return client.Quit()
}
