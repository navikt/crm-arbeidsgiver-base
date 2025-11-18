# formattedField

En gjenbrukbar Lightning Web Component som automatisk formaterer og viser ulike datatyper med riktig formatering.

## Beskrivelse

`formattedField` er en utility-komponent som tar inn en verdi og en type, og viser verdien med riktig formatering basert på datatypen. Komponenten bruker Salesforce sine innebygde `lightning-formatted-*` komponenter for konsistent formatering.

## API Properties

| Property | Type   | Beskrivelse                                              |
| -------- | ------ | -------------------------------------------------------- |
| `value`  | Any    | Verdien som skal formateres og vises                     |
| `type`   | String | Datatypen som bestemmer formateringen (case-insensitive) |

## Støttede typer

-   **`text`** - Vanlig tekst med linkify-funksjonalitet
-   **`email`** - E-postadresser med klikkbar mailto-link
-   **`phone`** - Telefonnumre med klikkbar tel-link
-   **`date`** / **`datetime`** - Datoer og tidspunkt
-   **`number`** / **`double`** / **`integer`** - Numeriske verdier
-   **`boolean`** - Boolean-verdier vist som ✅ (true) eller ⬜ (false)
-   **`customrichtext`** - Rich text-innhold
-   **`address`** - Adresser med strukturert visning
-   **`c_reference`** - URL-referanser med link og navn

## Brukseksempler

```html
<!-- Enkel tekst -->
<c-formatted-field value="Noe tekst" type="text"></c-formatted-field>

<!-- E-post -->
<c-formatted-field value="test@example.com" type="email"></c-formatted-field>

<!-- Nummer -->
<c-formatted-field value="{123456.78}" type="number"></c-formatted-field>

<!-- Boolean -->
<c-formatted-field value="{true}" type="boolean"></c-formatted-field>

<!-- Adresse -->
<c-formatted-field value="{addressObject}" type="address"> </c-formatted-field>

<!-- URL/Referanse -->
<c-formatted-field value="{urlObject}" type="c_reference"> </c-formatted-field>
```

## Dataformater

### Adresse-objekt

```javascript
{
    street: 'Gateadresse 1',
    city: 'Oslo',
    province: 'Oslo', // eller 'state'
    country: 'Norge',
    postalCode: '0123' // eller 'postal-code'
}
```

### URL/Referanse-objekt

```javascript
{
    link: 'https://example.com',
    name: 'Lenketekst'
}
```

## Fallback

Hvis ingen type er spesifisert, eller en ukjent type brukes, vil komponenten default til `text`-formatering.
