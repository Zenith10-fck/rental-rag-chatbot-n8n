# Rental Shop RAG Chatbot (n8n, demo)

A customer-support chatbot for a small rental shop, built so that it **answers only from the
shop's own FAQ and says so when it does not know**. The shop in the demo ("Cirebon PS Hub", a
PlayStation rental) is fictional, and all prices and rules are sample data.

Two n8n workflows:

| Workflow | Flow |
|---|---|
| `workflows/ingestion.json` | Manual trigger → Code node (the FAQ entries) → Cohere embeddings → Supabase row (`content` + `embedding`) |
| `workflows/retrieval.json` | Webhook (`chat_input`) → Cohere embedding of the question → Supabase vector search → Code node builds the knowledge text → Claude answers → reply (or a fallback message if the model call fails) |

## How it stays on the facts

- **Retrieval first.** The question is embedded (`input_type: search_query`) and matched against
  the stored FAQ with a similarity threshold of 0.6 and the top 5 matches.
- **The prompt only allows those documents.** The system prompt tells Claude to answer only from
  the retrieved text, never to guess a price or rule, and to give one fixed fallback sentence
  (ask for a WhatsApp number so an admin can follow up) when the answer is not in the documents.
- **Documents are fenced** in a `<dokumen>` block in the system prompt.
- **Model errors don't leave the chat hanging.** An `If` node checks the model response and returns
  a polite "queue is full, try again" message instead of an error.

Models: Cohere `embed-multilingual-v3.0` (1024 dimensions) for embeddings and Claude Haiku
(`claude-haiku-4-5-20251001`) for the answer.

## Setup

1. Run `setup.sql` in a Supabase project (pgvector). It creates `faq_documents` and the
   `match_faq_documents` function.
2. n8n → Import both workflows. Replace the placeholders:
   - the Cohere `Authorization` header (`Bearer REPLACE_WITH_API_KEY`) in both embedding nodes,
   - `YOUR-PROJECT.supabase.co` in the retrieval workflow, plus the Supabase credentials,
   - the Anthropic credential on `Message a model`.
3. Edit the FAQ list in the ingestion Code node, run the workflow once, then activate retrieval.
4. Ask a question:

```bash
curl -X POST "$N8N_URL/webhook/rental-chat" -H "Content-Type: application/json" \
  -d '{"chat_input":"Berapa sewa PS5 untuk 3 hari?"}'
```

The reply is in the `balasan_teks` field.

This is a demo workflow export, not a measured benchmark: there is no test set or accuracy figure.
Secrets and project addresses in the export were replaced with placeholders.
