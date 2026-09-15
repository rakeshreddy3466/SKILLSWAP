import { useEffect, useRef, useState } from 'react';
import { io } from 'socket.io-client';
import { addSkill, getSkills } from './api.js';

const ROOM = 'lobby';

export default function App() {
  const [skills, setSkills] = useState([]);
  const [form, setForm] = useState({ name: '', offers: '', wants: '' });
  const [formError, setFormError] = useState('');

  const [messages, setMessages] = useState([]);
  const [author, setAuthor] = useState('');
  const [text, setText] = useState('');
  const [connection, setConnection] = useState({ status: 'connecting', servedBy: '' });
  const socketRef = useRef(null);

  useEffect(() => {
    getSkills().then(setSkills).catch(() => setSkills([]));
  }, []);

  useEffect(() => {
    const socket = io();
    socketRef.current = socket;

    socket.on('connect', () => {
      setConnection((c) => ({ ...c, status: 'connected' }));
      socket.emit('join', ROOM, (res) => {
        if (res?.ok) setMessages(res.history);
      });
    });
    socket.on('hello', ({ servedBy }) => setConnection((c) => ({ ...c, servedBy })));
    socket.on('disconnect', () => setConnection((c) => ({ ...c, status: 'disconnected' })));
    socket.on('connect_error', () => setConnection((c) => ({ ...c, status: 'connection error' })));
    socket.on('message', (msg) => setMessages((prev) => [...prev, msg]));

    return () => socket.close();
  }, []);

  async function submitSkill(event) {
    event.preventDefault();
    setFormError('');
    try {
      const saved = await addSkill(form);
      setSkills((prev) => [saved, ...prev]);
      setForm({ name: '', offers: '', wants: '' });
    } catch (err) {
      setFormError(err.message);
    }
  }

  function sendMessage(event) {
    event.preventDefault();
    if (!author.trim() || !text.trim()) return;
    socketRef.current?.emit('message', { room: ROOM, author, text });
    setText('');
  }

  return (
    <main>
      <header>
        <h1>SkillSwap</h1>
        <p>Teach what you know, learn what you don't.</p>
        <span className={`status ${connection.status.replace(' ', '-')}`}>
          {connection.status}
          {connection.servedBy && ` · pod ${connection.servedBy}`}
        </span>
      </header>

      <section className="grid">
        <div className="card">
          <h2>Offer a skill</h2>
          <form onSubmit={submitSkill}>
            <input placeholder="Your name" value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })} />
            <input placeholder="I can teach..." value={form.offers}
              onChange={(e) => setForm({ ...form, offers: e.target.value })} />
            <input placeholder="I want to learn..." value={form.wants}
              onChange={(e) => setForm({ ...form, wants: e.target.value })} />
            <button type="submit">Post</button>
            {formError && <p className="error">{formError}</p>}
          </form>

          <ul className="skills">
            {skills.map((s) => (
              <li key={s.id}>
                <strong>{s.name}</strong> teaches <em>{s.offers}</em>, wants <em>{s.wants}</em>
              </li>
            ))}
            {skills.length === 0 && <li className="muted">No skills posted yet.</li>}
          </ul>
        </div>

        <div className="card">
          <h2>Lobby chat</h2>
          <ul className="messages">
            {messages.map((m, i) => (
              <li key={`${m.sentAt}-${i}`}>
                <strong>{m.author}</strong> {m.text}
                <small> via {m.servedBy}</small>
              </li>
            ))}
            {messages.length === 0 && <li className="muted">Say hi to the community.</li>}
          </ul>
          <form onSubmit={sendMessage} className="chat-form">
            <input placeholder="Name" value={author} onChange={(e) => setAuthor(e.target.value)} />
            <input placeholder="Message" value={text} onChange={(e) => setText(e.target.value)} />
            <button type="submit">Send</button>
          </form>
        </div>
      </section>
    </main>
  );
}
