import React, { useEffect, useState } from 'react';
import { EditorContent, useEditor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Link from '@tiptap/extension-link';
import Placeholder from '@tiptap/extension-placeholder';

export default function PublishingEditor({ id, creativeWorkType = 'Article', initialRecord = null }) {
  const [headline, setHeadline] = useState(initialRecord?.schema?.headline || initialRecord?.schema?.name || '');
  const [description, setDescription] = useState(initialRecord?.schema?.description || '');
  const [status, setStatus] = useState(initialRecord?.status || 'draft');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(initialRecord);
  const [presence, setPresence] = useState([]);
  const [revisions, setRevisions] = useState([]);

  const editor = useEditor({
    extensions: [
      StarterKit,
      Link,
      Placeholder.configure({
        placeholder: 'Start creating structured enterprise content...'
      })
    ],
    content: initialRecord?.schema?.articleBody || '<p></p>'
  });

  useEffect(() => {
    const recordId = saved?.id || id;
    if (!recordId) return;

    let active = true;

    async function syncCollaboration() {
      await fetch(`/api/content/${encodeURIComponent(recordId)}/presence`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          userId: 'system-user',
          name: 'System User',
          status: 'editing'
        })
      });

      const [presenceResponse, revisionsResponse] = await Promise.all([
        fetch(`/api/content/${encodeURIComponent(recordId)}/presence`),
        fetch(`/api/content/${encodeURIComponent(recordId)}/revisions`)
      ]);

      if (!active) return;

      setPresence(await presenceResponse.json());
      setRevisions(await revisionsResponse.json());
    }

    syncCollaboration();
    const interval = setInterval(syncCollaboration, 10000);

    return () => {
      active = false;
      clearInterval(interval);
    };
  }, [id, saved?.id]);

  async function save() {
    if (!editor) return;

    setSaving(true);

    const body = editor.getHTML();
    const json = editor.getJSON();

    const payload = {
      tenant: initialRecord?.tenant || 'default',
      slug: initialRecord?.slug || headline.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
      creativeWorkType,
      status,
      collaborators: presence.map((entry) => ({ userId: entry.userId, name: entry.name })),
      schema: {
        '@context': 'https://schema.org',
        '@type': creativeWorkType,
        ...(initialRecord?.schema || {}),
        headline,
        name: headline,
        description,
        articleBody: body,
        dateModified: new Date().toISOString()
      },
      editorState: json,
      updatedBy: 'system-user'
    };

    const response = await fetch(id ? `/api/content/${encodeURIComponent(id)}` : '/api/content', {
      method: id ? 'PATCH' : 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    setSaved(data);
    setStatus(data.status || status);
    setSaving(false);
  }

  async function transition(nextStatus) {
    const recordId = saved?.id || id;

    if (!recordId) {
      await save();
      return;
    }

    setSaving(true);

    const response = await fetch(`/api/content/${encodeURIComponent(recordId)}/workflow`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ status: nextStatus, actor: 'system-user' })
    });

    const data = await response.json();

    setSaved(data);
    setStatus(data.status || nextStatus);
    setSaving(false);
  }

  return (
    <div>
      <div>
        <input
          type="text"
          placeholder="Headline"
          value={headline}
          onChange={(event) => setHeadline(event.target.value)}
        />
      </div>

      <div>
        <textarea
          placeholder="Description"
          value={description}
          onChange={(event) => setDescription(event.target.value)}
        />
      </div>

      <div>
        <select value={status} onChange={(event) => setStatus(event.target.value)}>
          <option value="draft">draft</option>
          <option value="review">review</option>
          <option value="approved">approved</option>
          <option value="scheduled">scheduled</option>
          <option value="published">published</option>
          <option value="archived">archived</option>
        </select>
      </div>

      <section>
        <strong>Collaborators</strong>
        <ul>
          {presence.map((entry) => (
            <li key={entry.id}>{entry.name} — {entry.status}</li>
          ))}
        </ul>
      </section>

      <EditorContent editor={editor} />

      <div>
        <button onClick={save} disabled={saving}>{saving ? 'Saving...' : 'Save'}</button>
        <button onClick={() => transition('review')} disabled={saving}>Submit Review</button>
        <button onClick={() => transition('approved')} disabled={saving}>Approve</button>
        <button onClick={() => transition('published')} disabled={saving}>Publish</button>
        <button onClick={() => transition('archived')} disabled={saving}>Archive</button>
      </div>

      <section>
        <strong>Revision History</strong>
        <ul>
          {revisions.map((revision) => (
            <li key={revision.id}>{revision.reason} — {revision.actor} — {revision.createdAt}</li>
          ))}
        </ul>
      </section>

      {saved && <pre>{JSON.stringify(saved, null, 2)}</pre>}
    </div>
  );
}
