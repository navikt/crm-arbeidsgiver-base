# Account Highlights Panel

Viser Account-felter i en highlights panel på toppen av record page.

**Felter:**

-   Organisasjonsnummer (med kopier-knapp)
-   Bransje
-   Sektor
-   Antall ansatte
-   Registreringsår
-   Proff.no link
-   Overordnet konto (med popover preview)

**Komponenter:**

-   `TagAccountHighlightsPanel` (Hovedkomponent)

    -   Henter data via standard `@wire` funksjoner.
    -   Lager horisontale kolonner for å vise data, men bruker `highlightsPanelField` for å formatere felt/label
    -   Håndterer visning og funksjonalitet for kopier-knapp
    -   Håndterer input til popover funksjon for parent account og gruker `popover` for å lage link med hover funksjon
    -   Bruker `accountCompactView` for å generere innholdet i popover
    -   API input: `recordId`

-   `highlightsPanelField`

    -   Gjenbrukbar wrapper-komponent for label/value-par. Bruker slots for fleksibel content.
    -   Ansvar for konsistent styling av alle felter i highlights panel
    -   Slots: `label`, `value`

-   `accountCompactView`

    -   Viser compact view av account med relevante felter. Laster data via `@wire(getRecord)`.
    -   Ansvar for å hente parent account data og styrer hvordan den vises. Kontrollerer innholdet i popover preview av parent account i TagAccountHighlightsPanel.
    -   API input: `recordId`

-   `popover`
    -   Generisk popover-komponent med hover og click-funksjonalitet.
    -   Ansvar for å generere hover link for parent account i TagAccountHighlightsPanel og styre visning av popover.
    -   Funksjoner:
        -   Hover på link → åpner popover (auto-lukk ved mouse leave)
        -   Skjult button for åpning/lukking via keyboard
        -   Focus trap når åpnet via button og ESC-tast lukker popover
        -   Dynamisk posisjonering (venstre eller under, avhengig av plass)
    -   API input: `linkUrl`, `linkLabel`, `iconName`, `tooltip`, `title`
    -   Slots: `body` - innhold som vises i popover
