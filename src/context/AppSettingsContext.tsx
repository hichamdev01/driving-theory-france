import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useSQLiteContext } from 'expo-sqlite';
import { getCountries, getUserSettings, setSelectedCountry, setSelectedLanguage } from '../db/queries';
import { getString, type StringKey } from '../i18n/strings';
import type { Country, CountryCode, LanguageCode } from '../types';

interface AppSettingsContextValue {
  loading: boolean;
  countries: Country[];
  countryCode: CountryCode | null;
  languageCode: LanguageCode | null;
  countryName: string | null;
  chooseCountry: (code: CountryCode) => Promise<void>;
  chooseLanguage: (code: LanguageCode) => Promise<void>;
  resetSelection: () => Promise<void>;
  t: (key: StringKey, vars?: Record<string, string | number>) => string;
}

const AppSettingsContext = createContext<AppSettingsContextValue | null>(null);

export function AppSettingsProvider({ children }: { children: React.ReactNode }) {
  const db = useSQLiteContext();
  const [loading, setLoading] = useState(true);
  const [countries, setCountries] = useState<Country[]>([]);
  const [countryCode, setCountryCode] = useState<CountryCode | null>(null);
  const [languageCode, setLanguageCode] = useState<LanguageCode | null>(null);

  useEffect(() => {
    (async () => {
      const [countryList, settings] = await Promise.all([getCountries(db), getUserSettings(db)]);
      setCountries(countryList);
      setCountryCode(settings.selected_country_code);
      setLanguageCode(settings.selected_language_code);
      setLoading(false);
    })();
  }, [db]);

  const chooseCountry = useCallback(
    async (code: CountryCode) => {
      await setSelectedCountry(db, code);
      setCountryCode(code);
      setLanguageCode(null);
    },
    [db]
  );

  const chooseLanguage = useCallback(
    async (code: LanguageCode) => {
      await setSelectedLanguage(db, code);
      setLanguageCode(code);
    },
    [db]
  );

  const resetSelection = useCallback(async () => {
    setCountryCode(null);
    setLanguageCode(null);
  }, []);

  const t = useCallback(
    (key: StringKey, vars?: Record<string, string | number>) => getString(languageCode ?? 'en', key, vars),
    [languageCode]
  );

  const countryName = useMemo(
    () => countries.find((c) => c.code === countryCode)?.name ?? null,
    [countries, countryCode]
  );

  const value: AppSettingsContextValue = {
    loading,
    countries,
    countryCode,
    languageCode,
    countryName,
    chooseCountry,
    chooseLanguage,
    resetSelection,
    t,
  };

  return <AppSettingsContext.Provider value={value}>{children}</AppSettingsContext.Provider>;
}

export function useAppSettings(): AppSettingsContextValue {
  const ctx = useContext(AppSettingsContext);
  if (!ctx) throw new Error('useAppSettings must be used within AppSettingsProvider');
  return ctx;
}
