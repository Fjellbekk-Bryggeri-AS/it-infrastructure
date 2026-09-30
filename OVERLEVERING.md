# Overleveringsnotat – Fjellbekk Bryggeri AS

**Fra:** Ola Nordmann, Nordavind IT AS
**Dato:** 30. september 2026

Hei!

Her er en kort oppsummering av løsningen vi har driftet for dere. Alt ligger i
Terraform, så det skal være rett fram å ta over.

## Arkitektur

- Én webserver (Ubuntu + nginx) som serverer nettbutikken.
- Kampanjebildene ligger i en storage-konto, slik at markedsavdelingen kan
  bytte dem uten å gå via oss.
- Ordreeksporten fra nettbutikken legges i samme storage-konto.
- Test og prod er satt opp helt likt.

## Sikkerhet

- Brannmuren slipper bare inn webtrafikk (port 80). Alt annet er stengt.
- Det er ingen passord på serveren; vi bruker SSH-nøkkel.
- Checkov kjører i pipelinen og er grønn.

## Kjente ting

- Webserveren ble oppgradert til større størrelse i prod i forbindelse med
  julehandelen i fjor. Den kan nok skaleres ned igjen.
- Subnettene `app` og `data` er satt av til en fremtidig integrasjon mot
  regnskapssystemet. Ikke i bruk i dag.

## Tilgang

SSH-nøkkelen som ligger i konfigurasjonen, er min. Den kan dere bytte ut når
dere har fått på plass deres egen.

Lykke til!

Mvh
Ola
