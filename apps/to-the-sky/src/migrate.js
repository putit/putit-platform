const pool = require('./db');

const createSchema = `
CREATE TABLE IF NOT EXISTS spells (
  id SERIAL PRIMARY KEY,
  slug VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  level INTEGER NOT NULL,
  school VARCHAR(100) NOT NULL,
  casting_time VARCHAR(100) NOT NULL,
  range VARCHAR(100) NOT NULL,
  components VARCHAR(100) NOT NULL,
  duration VARCHAR(100) NOT NULL,
  description TEXT NOT NULL
);
`;

const spells = [
  {
    slug: 'cone-of-cold',
    name: 'Cone of Cold',
    level: 5,
    school: 'Evocation',
    casting_time: '1 action',
    range: 'Self (60-foot cone)',
    components: 'V, S, M',
    duration: 'Instantaneous',
    description: 'A blast of cold air erupts from your hands. Each creature in a 60-foot cone must make a Constitution saving throw. A creature takes 8d8 cold damage on a failed save, or half as much damage on a successful one.'
  },
  {
    slug: 'fireball',
    name: 'Fireball',
    level: 3,
    school: 'Evocation',
    casting_time: '1 action',
    range: '150 feet',
    components: 'V, S, M',
    duration: 'Instantaneous',
    description: 'A bright streak flashes from your pointing finger to a point you choose within range and then blossoms with a low roar into an explosion of flame. Each creature in a 20-foot-radius sphere centered on that point must make a Dexterity saving throw. A target takes 8d6 fire damage on a failed save, or half as much damage on a successful one.'
  },
  {
    slug: 'magic-missile',
    name: 'Magic Missile',
    level: 1,
    school: 'Evocation',
    casting_time: '1 action',
    range: '120 feet',
    components: 'V, S',
    duration: 'Instantaneous',
    description: 'You create three glowing darts of magical force. Each dart hits a creature of your choice that you can see within range. A dart deals 1d4 + 1 force damage to its target. The darts all strike simultaneously, and you can direct them to hit one creature or several.'
  },
  {
    slug: 'shield',
    name: 'Shield',
    level: 1,
    school: 'Abjuration',
    casting_time: '1 reaction',
    range: 'Self',
    components: 'V, S',
    duration: '1 round',
    description: 'An invisible barrier of magical force appears and protects you. Until the start of your next turn, you have a +5 bonus to AC, including against the triggering attack, and you take no damage from magic missile.'
  },
  {
    slug: 'lightning-bolt',
    name: 'Lightning Bolt',
    level: 3,
    school: 'Evocation',
    casting_time: '1 action',
    range: 'Self (100-foot line)',
    components: 'V, S, M',
    duration: 'Instantaneous',
    description: 'A stroke of lightning forming a line 100 feet long and 5 feet wide blasts out from you in a direction you choose. Each creature in the line must make a Dexterity saving throw. A creature takes 8d6 lightning damage on a failed save, or half as much damage on a successful one.'
  },
  {
    slug: 'cure-wounds',
    name: 'Cure Wounds',
    level: 1,
    school: 'Evocation',
    casting_time: '1 action',
    range: 'Touch',
    components: 'V, S',
    duration: 'Instantaneous',
    description: 'A creature you touch regains a number of hit points equal to 1d8 + your spellcasting ability modifier. This spell has no effect on undead or constructs.'
  },
  {
    slug: 'detect-magic',
    name: 'Detect Magic',
    level: 1,
    school: 'Divination',
    casting_time: '1 action',
    range: 'Self',
    components: 'V, S',
    duration: 'Concentration, up to 10 minutes',
    description: 'For the duration, you sense the presence of magic within 30 feet of you. If you sense magic in this way, you can use your action to see a faint aura around any visible creature or object in the area that bears magic, and you learn its school of magic, if any.'
  },
  {
    slug: 'invisibility',
    name: 'Invisibility',
    level: 2,
    school: 'Illusion',
    casting_time: '1 action',
    range: 'Touch',
    components: 'V, S, M',
    duration: 'Concentration, up to 1 hour',
    description: 'A creature you touch becomes invisible until the spell ends. Anything the target is wearing or carrying is invisible as long as it is on the target\'s person. The spell ends for a target that attacks or casts a spell.'
  },
  {
    slug: 'counterspell',
    name: 'Counterspell',
    level: 3,
    school: 'Abjuration',
    casting_time: '1 reaction',
    range: '60 feet',
    components: 'S',
    duration: 'Instantaneous',
    description: 'You attempt to interrupt a creature in the process of casting a spell. If the creature is casting a spell of 3rd level or lower, its spell fails and has no effect. If it is casting a spell of 4th level or higher, make an ability check using your spellcasting ability. The DC equals 10 + the spell\'s level. On a success, the creature\'s spell fails and has no effect.'
  },
  {
    slug: 'teleport',
    name: 'Teleport',
    level: 7,
    school: 'Conjuration',
    casting_time: '1 action',
    range: '10 feet',
    components: 'V',
    duration: 'Instantaneous',
    description: 'This spell instantly transports you and up to eight willing creatures of your choice that you can see within range, or a single object that you can see within range, to a destination you select. If you target an object, it must be able to fit entirely inside a 10-foot cube, and it can\'t be held or carried by an unwilling creature.'
  }
];

async function migrate() {
  const client = await pool.connect();
  try {
    console.log('Running migrations...');

    await client.query(createSchema);
    console.log('Schema created.');

    for (const spell of spells) {
      await client.query(
        `INSERT INTO spells (slug, name, level, school, casting_time, range, components, duration, description)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         ON CONFLICT (slug) DO NOTHING`,
        [spell.slug, spell.name, spell.level, spell.school, spell.casting_time, spell.range, spell.components, spell.duration, spell.description]
      );
    }
    console.log('Spells seeded.');

    console.log('Migrations complete.');
  } finally {
    client.release();
    await pool.end();
  }
}

migrate().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
