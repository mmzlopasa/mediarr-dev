// Package words holds the texts the server writes itself, such as e-mails, in each language a person
// can choose. English is the main language and what shows when a text is missing.
package words

import "fmt"

// Key names one text.
type Key string

// The texts there are.
const (
	TestSubject    Key = "test.subject"
	TestBody       Key = "test.body"
	SharedSubject  Key = "shared.subject"
	SharedBody     Key = "shared.body"
	ResetSubject   Key = "reset.subject"
	ResetBody      Key = "reset.body"
	QuietSubject   Key = "quiet.subject"
	QuietBody      Key = "quiet.body"
	QuietDevices   Key = "quiet.devices"
	QuietSomeone   Key = "quiet.someone"
	dateTimeLayout     = "2006-01-02 15:04 UTC"
)

// DateTime is how a moment is written in an e-mail, the same in every language.
const DateTime = dateTimeLayout

var texts = map[string]map[Key]string{
	"en": {
		TestSubject:   "Mediarr test message",
		TestBody:      "Email from your Mediarr server works.",
		SharedSubject: "An album was shared with you: %s",
		SharedBody:    "%s shared the album \"%s\" with you on Mediarr.",
		ResetSubject:  "Set a new Mediarr password",
		ResetBody:     "Someone asked to set a new password for this account.\n\n%s\n\nThe link works once, for one hour. If this was not you, you can ignore this message.",
		QuietSubject:  "%s has stopped backing up to Mediarr",
		QuietBody:     "%s last reported on its backup on %s.\n\nNew photos on it may not be safe on your Mediarr server yet. Open Mediarr on the device: it reports when it starts. If backup was turned off or the app was signed out, turn it on again in Backup.\n",
		QuietDevices:  "\nYour devices: %s/account/devices\n",
		QuietSomeone:  "A device",
	},
	"hr": {
		TestSubject:   "Probna poruka s Mediarra",
		TestBody:      "E-pošta s vašeg Mediarr poslužitelja radi.",
		SharedSubject: "S vama je podijeljen album: %s",
		SharedBody:    "%s je s vama podijelio album \"%s\" na Mediarru.",
		ResetSubject:  "Postavite novu lozinku za Mediarr",
		ResetBody:     "Netko je zatražio novu lozinku za ovaj račun.\n\n%s\n\nPoveznica vrijedi jednom, sat vremena. Ako to niste bili vi, zanemarite ovu poruku.",
		QuietSubject:  "%s više ne radi sigurnosnu kopiju na Mediarr",
		QuietBody:     "%s se zadnji put javio o sigurnosnoj kopiji %s.\n\nNove fotke na njemu možda još nisu sigurne na vašem Mediarr poslužitelju. Otvorite Mediarr na uređaju: javi se čim se pokrene. Ako je kopija isključena ili je aplikacija odjavljena, ponovno je uključite pod Sigurnosna kopija.\n",
		QuietDevices:  "\nVaši uređaji: %s/account/devices\n",
		QuietSomeone:  "Uređaj",
	},
	"de": {
		TestSubject:   "Mediarr-Testnachricht",
		TestBody:      "E-Mails von deinem Mediarr-Server funktionieren.",
		SharedSubject: "Ein Album wurde mit dir geteilt: %s",
		SharedBody:    "%s hat das Album \"%s\" auf Mediarr mit dir geteilt.",
		ResetSubject:  "Neues Mediarr-Passwort festlegen",
		ResetBody:     "Jemand hat ein neues Passwort für dieses Konto angefordert.\n\n%s\n\nDer Link funktioniert einmal und eine Stunde lang. Wenn du das nicht warst, kannst du diese Nachricht ignorieren.",
		QuietSubject:  "%s sichert nicht mehr auf Mediarr",
		QuietBody:     "%s hat sich zuletzt am %s zur Sicherung gemeldet.\n\nNeue Fotos darauf sind vielleicht noch nicht auf deinem Mediarr-Server gesichert. Öffne Mediarr auf dem Gerät: Es meldet sich beim Start. Wenn die Sicherung ausgeschaltet oder die App abgemeldet wurde, schalte sie unter Sicherung wieder ein.\n",
		QuietDevices:  "\nDeine Geräte: %s/account/devices\n",
		QuietSomeone:  "Ein Gerät",
	},
	"sl": {
		TestSubject:   "Testno sporočilo Mediarr",
		TestBody:      "E-pošta z vašega strežnika Mediarr deluje.",
		SharedSubject: "Z vami je bil deljen album: %s",
		SharedBody:    "%s je z vami delil album \"%s\" v Mediarru.",
		ResetSubject:  "Nastavite novo geslo za Mediarr",
		ResetBody:     "Nekdo je zahteval novo geslo za ta račun.\n\n%s\n\nPovezava deluje enkrat, eno uro. Če to niste bili vi, lahko to sporočilo prezrete.",
		QuietSubject:  "%s ne varnostno kopira več v Mediarr",
		QuietBody:     "%s se je o varnostni kopiji nazadnje oglasil %s.\n\nNove fotografije na njem morda še niso varne na vašem strežniku Mediarr. Odprite Mediarr na napravi: oglasi se, ko se zažene. Če je bilo varnostno kopiranje izklopljeno ali je bila aplikacija odjavljena, ga znova vklopite pod Varnostno kopiranje.\n",
		QuietDevices:  "\nVaše naprave: %s/account/devices\n",
		QuietSomeone:  "Naprava",
	},
}

// Say writes a text in a language, filling in what it is given.
func Say(language string, key Key, args ...any) string {
	text, ok := texts[language][key]
	if !ok {
		text = texts["en"][key]
	}
	if len(args) == 0 {
		return text
	}
	return fmt.Sprintf(text, args...)
}
