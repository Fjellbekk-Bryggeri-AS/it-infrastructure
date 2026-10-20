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
endre. Drift-sjekken går hvert kvarter og avslører alt som er endret utenom
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
8. **Be Sikkerhet & Release promotere** SHA-en til prod.

### Regler

- Én ticket = én PR. Små endringer er lettere å lese og lettere å rulle tilbake.
- Ingen merger sin egen PR uten godkjenning.
- En ticket kan avvises. Er en forespørsel dårlig, svar på ticketen med
  hvorfor, og foreslå et alternativ.
- Går nettsiden ned: si fra høyt i rommet. On-call (Sikkerhet & Release)
  koordinerer.

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
| Drift    | Hvert kvarter, eller for hånd       | Sjekker om Azure har glidd fra koden          |
