export async function getSkills() {
  const res = await fetch('/api/skills');
  if (!res.ok) throw new Error('Could not load skills');
  return res.json();
}

export async function addSkill(skill) {
  const res = await fetch('/api/skills', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(skill),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(body.errors?.join(', ') || 'Could not save skill');
  return body;
}
