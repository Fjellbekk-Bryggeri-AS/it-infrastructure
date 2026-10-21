# Fjellbekk Bryggeri – drift

Velkommen til IT-avdelingen i Fjellbekk Bryggeri AS.

Nordavind IT AS har driftet nettbutikken vår siden 2023. Avtalen er sagt opp,
og fra i dag er det **dere** som har ansvaret. Nordavind har levert dette
repoet og et kort overleveringsnotat ([OVERLEVERING.md](OVERLEVERING.md)).
Nettbutikken er i drift, kundene handler, og den skal fortsette å virke.

| Miljø | Nettbutikk                                                  |
| ----- | ----------------------------------------------------------- |
| test  | http://fjellbekk-bryggeri-test.norwayeast.cloudapp.azure.com |
| prod  | http://fjellbekk-bryggeri.norwayeast.cloudapp.azure.com      |

## Teamene

| Team                    | Eier                                                   |
| ----------------------- | ------------------------------------------------------ |
| **Nettverk**            | `stacks/nettverk/` – VNet, subnett, brannmur (NSG)     |
| **Data**                | `stacks/data/` – lagring, kampanjebilder, ordrer       |
| **Plattform**           | `stacks/plattform/` – webserveren og selve nettsiden   |
| **Sikkerhet & Release** | `.github/`, `.checkov.yaml`, `.tflint.hcl`, skriptene – og godkjenning til prod |

Konfigurasjonen per miljø ligger i `terraform-projects/config/<miljø>/<stack>.tfvars`
og eies av samme team som stacken. Se `.github/CODEOWNERS`.

## Slik jobber vi

**Ingen endrer noe i Azure-portalen.** Portalen er til å se, ikke til å
endre. Drift-sjekken kjører jevnlig og avslører alt som er endret utenom
koden – og hvem som må rydde opp. **Alle** endringer går denne veien:

```text
 ticket (issue)
   │
   ▼
 gren + commit ──► pull request ──► CI: kodekontroll + plan mot test og prod
                                    │
                                    ▼
                         godkjenning fra eier-teamet (CODEOWNERS)
                                    │
                                    ▼
                    merge til main ──► CD test (automatisk)
                                    │
                                    ▼
                 CD prod med SHA-en ──► godkjenning fra Sikkerhet & Release
```

1. **Ta en ticket.** Tildel den til deg selv på GitHub så andre ser at den er tatt.
2. **Lag en gren:** `git switch -c 12-nytt-subnett` (ticketnummer først).
3. **Kjør kontrollene lokalt** før du pusher:
   `bash terraform-projects/scripts/valider.sh`
4. **Åpne en PR** med `Closes #12` i beskrivelsen. Fyll ut malen.
5. **Les planen** som CI legger på PR-en – både test og prod. Står det
   `destroy` eller `must be replaced`, stopp og tenk.
6. **Få godkjenning** fra eier-teamet, merge, og følg med på *CD test*.
7. **Sjekk nettsiden i test.** Ser alt riktig ut?
8. **Be Sikkerhet & Release promotere** SHA-en til prod: *Actions* → *CD prod*
   → **Run workflow** → lim inn hele SHA-en fra den vellykkede *CD test*-
   kjøringen (tittelen er `test ← <sha>`). Jobben venter til noen i
   Sikkerhet & Release trykker *Review deployments* → *Approve*.

Alle workflowene kan startes fra nettleseren: *Actions* → velg workflow →
**Run workflow**. Du trenger ikke `gh` i terminalen.

### Regler

- Én ticket = én PR. Små endringer er lettere å lese og lettere å rulle tilbake.
- Ingen merger sin egen PR uten godkjenning.
- En ticket kan avvises. Er en forespørsel dårlig, svar på ticketen med
  hvorfor, og foreslå et alternativ.
- Går nettsiden ned: si fra høyt i rommet. On-call (Sikkerhet & Release)
  koordinerer.

## Når noe er galt

En hendelse er noe som er galt **nå** – nettbutikken er nede, et bilde er
borte, drift-sjekken er rød. Da er målet å få det til å virke igjen, trygt,
og å forstå hva som skjedde. Ikke å fikse alt på én gang.

1. **Ta ticketen**, og skriv en kort kommentar: «Vi ser på det.» Da vet alle
   hvem som eier hendelsen.
2. **Bekreft symptomet selv.** Åpne nettsiden. Stemmer det som står i
   ticketen?
3. **Finn ut hva som er annerledes enn koden.** To veier, samme svar:
   - *Actions* → *Drift* → **Run workflow** → åpne kjøringen → *Summary*
     viser planen per stack og miljø.
   - Eller kjør plan lokalt (se under).

   Står det `No changes` overalt, stemmer Azure med koden – og feilen må
   ligge et annet sted.
4. **Bestem hva som er riktig.** Koden er fasiten – men ikke nødvendigvis.
   For hver endring dere finner: skal den **bort** (rull ut koden på nytt),
   eller skal den **inn i koden** (vanlig PR)?
5. **Gjenopprett fra koden**, ikke fra portalen. Rull ut den SHA-en som
   allerede er ute – den står i tittelen på siste vellykkede *CD prod*-
   kjøring (`prod ← <sha>`). Ikke ta med nye, uprøvde endringer fra main
   midt i en hendelse.
6. **Verifiser.** Nettsiden virker, og en ny Drift-kjøring er grønn.
7. **Lukk ticketen med en kort rapport:** når startet det, hva var årsaken,
   hva gjorde dere, hvor lenge varte det. Det er råstoffet til postmortem.

Portalen kan du gjerne *lese* i – *Activity log* på en ressurs viser hvem
som har endret hva, og når.

## Kjør plan lokalt

Du har **lesetilgang** til state. Det holder for `terraform plan`, men ikke
for `apply`: Terraform får verken låst eller skrevet state fra maskinen din.
Utrulling skjer bare gjennom pipelinen.

Logg inn og velg abonnementet:

```bash
az login
az account set --subscription sub_tenant03ntnu
```

**Alle stackene på én gang** (macOS, Linux eller Git Bash på Windows):

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
bash terraform-projects/scripts/kjor.sh prod drift     # eller: test plan
```

Sammendraget havner i `terraform-projects/rapport.md`.

**Én stack for hånd** (PowerShell vist – i bash: `export` i stedet for `$env:`):

```powershell
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
cd terraform-projects/stacks/nettverk
terraform init -reconfigure -backend-config="../../shared/backend.hcl" -backend-config="key=fjellbekk/prod/nettverk.tfstate"
terraform plan -lock=false -var-file="../../config/prod/nettverk.tfvars"
```

- `-reconfigure` trengs når du bytter miljø i samme mappe – ellers spør
  Terraform om å flytte state fra test til prod. Svar **aldri** ja på det.
- `-lock=false` fordi du bare har lesetilgang. Det er trygt for `plan`.
- Rekkefølgen betyr noe: `plattform` leser outputs fra `nettverk` og `data`.

## Stackene

```text
terraform-projects/
├── stacks/
│   ├── nettverk/     ← rulles ut først
│   ├── data/
│   └── plattform/    ← leser nettverk og data via terraform_remote_state
├── config/
│   ├── test/         ← én .tfvars per stack
│   └── prod/
├── shared/backend.hcl
└── scripts/
    ├── valider.sh    ← fmt, validate, TFLint, Checkov
    └── kjor.sh       ← plan / apply / drift for alle stackene, i rekkefølge
```

State ligger i `fjellbekk/<miljø>/<stack>.tfstate`.

## Workflows

| Workflow | Når                                 | Hva                                           |
| -------- | ----------------------------------- | --------------------------------------------- |
| CI       | Hver PR                             | Kodekontroll, plan mot test og prod som kommentar |
| CD test  | Hver merge til main                 | Ruller ut alle stackene til test              |
| CD prod  | For hånd, med SHA                   | Promoterer en testet commit til prod (krever godkjenning) |
| Drift    | Jevnlig, eller for hånd             | Sjekker om Azure har glidd fra koden          |
