import type { SQLiteDatabase } from 'expo-sqlite';
import { CREATE_TABLES_SQL, CONTENT_VERSION } from './schema';
import { seedContent } from './seed';

export async function initDatabase(db: SQLiteDatabase): Promise<void> {
  await db.execAsync(CREATE_TABLES_SQL);

  const row = await db.getFirstAsync<{ content_version: number }>(
    'SELECT content_version FROM user_settings WHERE id = 1'
  );

  if (!row || row.content_version !== CONTENT_VERSION) {
    await seedContent(db);
  }
}
