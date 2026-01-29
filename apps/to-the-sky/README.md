# To The Sky - D&D Spells API

A simple Node.js REST API for querying D&D spells.

## Requirements

- Node.js 20+
- PostgreSQL

## Environment Variables

The app can also use a `.env` file at its root directory.

| Variable            | Description                            |
| ------------------- | -------------------------------------- |
| `DATABASE_HOST`     | Database host                          |
| `DATABASE_PORT`     | Database port                          |
| `DATABASE_NAME`     | Database name                          |
| `DATABASE_USERNAME` | Database username                      |
| `DATABASE_PASSWORD` | Database password                      |
| `PORT`              | Server port (only needed for the app)  |

## Setup

Install dependencies
```bash
npm install
```

Create schema and seed data
```bash
npm run migrate
```

Start the app
```
npm start
```

## API Routes

### `GET /health`

Health check endpoint that pings the database.

**Response 200:**
```json
{ "status": "healthy" }
```

**Response 500:**
```json
{ "status": "unhealthy", "error": "..." }
```

### `GET /spells`

Returns a list of all spell slugs.

**Response 200:**
```json
["cone-of-cold", "counterspell", "cure-wounds", "detect-magic", ...]
```

### `GET /spells/:slug`

Returns details for a specific spell.

**Example:** `GET /spells/cone-of-cold`

**Response 200:**
```json
{
  "name": "Cone of Cold",
  "slug": "cone-of-cold",
  "level": 5,
  "school": "Evocation",
  "castingTime": "1 action",
  "range": "Self (60-foot cone)",
  "components": "V, S, M",
  "duration": "Instantaneous",
  "description": "A blast of cold air erupts from your hands..."
}
```

**Response 404:**
```json
{ "error": "Spell not found" }
```
