# Statische Website auf AWS

Terraform-Code für eine statische Website hinter CloudFront. Die Dateien liegen in einem
privaten S3-Bucket, erreichbar ist die Seite über eine eigene Domain mit eigenem
TLS-Zertifikat.

Portfolio im Kurs Cloud Programming (DLBSEPCP01_D), Aufgabe 1.
IU Internationale Hochschule, Studiengang Softwareentwicklung.

## Aufbau

- `providers.tf` Versionen, die beiden Provider, gemeinsame Tags
- `variables.tf` Region, Bucket-Name, Domain
- `s3.tf` Bucket, Public Access Block, Verschlüsselung, Bucket Policy, Objekte
- `cloudfront.tf` Origin Access Control, Distribution, Fehlerseiten
- `acm.tf` Zertifikat und Validierung
- `route53.tf` Hosted Zone, Validierungs- und Alias-Records
- `outputs.tf` Adresse der Website, Nameserver, IDs für Folgebefehle
- `website/` die auszuliefernden Dateien

## Voraussetzungen

Terraform ab 1.5, ein AWS-Konto mit konfigurierten Zugangsdaten und eine Domain, bei der
man die Nameserver selbst setzen kann. Zugangsdaten stehen nirgends im Code. Terraform
nutzt die üblichen Quellen des AWS-SDK, also Umgebungsvariablen oder das Profil aus
`~/.aws/credentials`.

## Konfiguration

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
```

In `terraform.tfvars` gehören `bucket_name` und `domain_name`. Der Bucket-Name muss
weltweit eindeutig sein. Die Datei selbst ist in der `.gitignore` ausgeschlossen, die
`.terraform.lock.hcl` dagegen bewusst eingecheckt, damit ein Dritter dieselben
Provider-Versionen bekommt.

## Bereitstellung

Die Bereitstellung läuft in zwei Durchgängen. Das ACM-Zertifikat wird per DNS validiert.
Der Eintrag dafür liegt in der Hosted Zone bei Route 53, abgefragt wird er aber über die
Nameserver beim Domain-Anbieter. Stehen dort noch die alten, findet ACM nichts und der
Apply läuft in einen Timeout.

```bash
terraform apply -target=aws_route53_zone.website
terraform output route53_name_servers
```

Die vier ausgegebenen Nameserver beim Anbieter eintragen und die alten ersetzen. Je nach
Anbieter dauert es Minuten bis Stunden, bis das greift.

```bash
dig +short NS deine-domain.de
```

Sobald dort die AWS-Nameserver erscheinen, folgt der zweite Durchgang.

```bash
terraform apply
terraform output website_url
```

Der braucht ein paar Minuten, eine CloudFront-Distribution rollt nicht sofort aus.

Zum Gegenprüfen drei Aufrufe. `curl -I http://deine-domain.de` muss mit 301 auf HTTPS
umleiten. `terraform plan` muss "No changes" melden. Und der Bucket hat neben der Domain
noch eine eigene Adresse der Form `https://BUCKET.s3.REGION.amazonaws.com/index.html`.
Die muss mit 403 abgewiesen werden, denn nur so ist belegt, dass die Dateien
ausschließlich über CloudFront erreichbar sind.

## Abbau

```bash
terraform destroy
```

Nimmt die Hosted Zone mit. Wer die Domain später wieder nutzt, muss die Nameserver erneut
umstellen. Laufende Kosten entstehen praktisch nur durch diese Zone, 0,50 USD im Monat.

## Notizen zum Aufbau

Ein paar Entscheidungen, die sich aus dem Code allein nicht erklären.

- Zwei Provider, weil CloudFront Zertifikate ausschließlich aus us-east-1 annimmt. Alles
  andere liegt in eu-central-1.
- Eigenes Zertifikat statt des mitgelieferten. Mit dem Default-Zertifikat steht die
  Security Policy fest auf TLSv1, `minimum_protocol_version` wird dann ignoriert.
- A- und AAAA-Record als Alias, weil ein CNAME auf der Apex-Domain nicht zulässig ist.
- 403 und 404 landen beide auf `error.html`. Die Bucket Policy erlaubt nur `GetObject`,
  kein `ListBucket`, deshalb antwortet S3 auf einen unbekannten Pfad mit 403.
- Die Dateinamen bleiben gleich. Nach einer Änderung an den Dateien unter `website/`
  braucht es deshalb eine Invalidierung des CloudFront-Caches, sonst liefert das Edge-Netz
  noch eine Weile die alte Fassung aus.
- State liegt lokal. Terraform merkt sich in `terraform.tfstate`, welche Ressourcen es
  angelegt hat. Üblicher wäre, diese Datei in einen S3-Bucket zu legen. Der müsste dann
  aber schon stehen, bevor `terraform init` läuft, denn das Backend wird eingerichtet,
  bevor die erste Ressource entsteht. Aus derselben Konfiguration heraus lässt er sich
  also nicht anlegen, jemand müsste ihn von Hand erzeugen. Bei einer einzigen
  bearbeitenden Person macht das die Reproduzierbarkeit schlechter statt besser.
- Keine Module, jede Ressource kommt genau einmal vor.
