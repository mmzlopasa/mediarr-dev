# Testni podaci

`make testdata` slaže oko 100 mješovitih datoteka u `TESTDATA` (zadano `.dev/testdata`). `make testdata SCALE=100` slaže punih 2.000. Ne idu u repo.

Većina je generirana, s Gaussovim šumom koji se komprimira slično kao prave fotke. Svaka datoteka je jedinstvena.

Generirane datoteke ne pokrivaju sve što snimaju stvarni uređaji, a sintetički Live Photo nije isto što i onaj s iPhonea. Prije v1.0 treba test sa stvarnim fotkama s mobitela.

`scripts/raw-samples.txt` navodi javne RAW uzorke s provjerom checksuma: u svakom retku su SHA-256 i URL.

`broken/` namjerno sadrži neispravne datoteke, koje moraju završiti s jasnom greškom, a ne srušiti worker.
