const express = require('express');
const pool = require('./db');

const app = express();
const PORT = process.env.PORT;

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'healthy' });
  } catch (err) {
    console.error('Health check failed:', err.message);
    res.status(500).json({ status: 'unhealthy', error: err.message });
  }
});

app.get('/spells', async (req, res) => {
  try {
    const result = await pool.query('SELECT slug FROM spells ORDER BY name');
    res.json(result.rows.map(row => row.slug));
  } catch (err) {
    console.error('Error fetching spells:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/spells/:slug', async (req, res) => {
  const { slug } = req.params;
  try {
    const result = await pool.query('SELECT * FROM spells WHERE slug = $1', [slug]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Spell not found' });
    }
    const spell = result.rows[0];
    res.json({
      name: spell.name,
      slug: spell.slug,
      level: spell.level,
      school: spell.school,
      castingTime: spell.casting_time,
      range: spell.range,
      components: spell.components,
      duration: spell.duration,
      description: spell.description
    });
  } catch (err) {
    console.error('Error fetching spell:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
