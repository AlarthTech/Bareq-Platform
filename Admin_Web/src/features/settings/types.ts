// API Response Types
export interface CityApiResponse {
  id: number;
  name: string;
  code: string | null;
  isActive: boolean;
}

export interface LanguageApiResponse {
  id: number;
  name: string;
  code: string | null;
  isActive: boolean;
}

export interface NationalityApiResponse {
  id: number;
  name: string;
  code: string | null;
  isActive: boolean;
}

// UI Types (mapped from API)
export interface City {
  id: string;
  name: string;
  nameAr: string;
  code: string | null;
  isActive: boolean;
}

export interface Language {
  id: string;
  name: string;
  nameAr: string;
  code: string | null;
  isActive: boolean;
}

export interface Nationality {
  id: string;
  name: string;
  nameAr: string;
  code: string | null;
  isActive: boolean;
}
