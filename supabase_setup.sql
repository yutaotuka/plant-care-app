-- =============================================
-- Midori — 植物ケア管理アプリ Supabase セットアップ
-- Supabase の SQL Editor にこれを貼り付けて実行してください
-- =============================================

-- 植物テーブル
create table plants (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  species text,
  icon text default '🌿',
  photo_url text,
  location text,
  water_days int default 7,
  fert_days int default 30,
  prune_days int default 60,
  repot_days int default 365,
  note text,
  created_at timestamptz default now()
);

-- ケア記録テーブル
create table care_logs (
  id uuid default gen_random_uuid() primary key,
  plant_id uuid references plants(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  type text not null, -- water / fertilize / prune / repot / photo / note
  date date not null default current_date,
  note text,
  photo_url text,
  created_at timestamptz default now()
);

-- Row Level Security（他ユーザーのデータは見えない）
alter table plants enable row level security;
alter table care_logs enable row level security;

create policy "自分のデータのみ参照" on plants
  for all using (auth.uid() = user_id);

create policy "自分のデータのみ参照" on care_logs
  for all using (auth.uid() = user_id);

-- Storage バケット（写真保存用）
insert into storage.buckets (id, name, public) values ('plant-photos', 'plant-photos', true);

create policy "認証済みユーザーはアップロード可" on storage.objects
  for insert with check (bucket_id = 'plant-photos' and auth.role() = 'authenticated');

create policy "全員が閲覧可" on storage.objects
  for select using (bucket_id = 'plant-photos');

create policy "自分のファイルは削除可" on storage.objects
  for delete using (bucket_id = 'plant-photos' and auth.uid()::text = (storage.foldername(name))[1]);
