-- Supabase / Postgres setup for the two n8n workflows.
-- Reconstructed from the workflow nodes (table, columns, RPC name and parameters). It was not
-- exported from a live database, so check it against your own project before relying on it.
create extension if not exists vector;

create table if not exists faq_documents (
  id bigint generated always as identity primary key,
  content text not null,
  embedding vector(1024)            -- Cohere embed-multilingual-v3.0 returns 1024 dimensions
);

create or replace function match_faq_documents(
  query_embedding vector(1024),
  match_threshold float,
  match_count int
)
returns table (id bigint, content text, similarity float)
language sql stable
as $$
  select id, content, 1 - (embedding <=> query_embedding) as similarity
  from faq_documents
  where 1 - (embedding <=> query_embedding) > match_threshold
  order by embedding <=> query_embedding
  limit match_count;
$$;
