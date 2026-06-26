import { apiClient } from '../../core/api/client';
import type {
  City,
  Language,
  Nationality,
  CityApiResponse,
  LanguageApiResponse,
  NationalityApiResponse,
} from './types';

// Helper function to map API response to UI format
const mapCityResponse = (apiCity: CityApiResponse): City => ({
  id: apiCity.id.toString(),
  name: apiCity.name, // Assuming name is in Arabic, we'll use it for both
  nameAr: apiCity.name,
  code: apiCity.code,
  isActive: apiCity.isActive,
});

const mapLanguageResponse = (apiLang: LanguageApiResponse): Language => ({
  id: apiLang.id.toString(),
  name: apiLang.name, // Assuming name is in Arabic, we'll use it for both
  nameAr: apiLang.name,
  code: apiLang.code,
  isActive: apiLang.isActive,
});

const mapNationalityResponse = (apiNat: NationalityApiResponse): Nationality => ({
  id: apiNat.id.toString(),
  name: apiNat.name, // Assuming name is in Arabic, we'll use it for both
  nameAr: apiNat.name,
  code: apiNat.code,
  isActive: apiNat.isActive,
});

export const settingsApi = {
  // Cities
  getCities: async (): Promise<City[]> => {
    try {
      const response = await apiClient.get<CityApiResponse[]>('/Cities/GetAllCities');
      return response.map(mapCityResponse);
    } catch (error) {
      console.error('Error fetching cities:', error);
      throw error;
    }
  },

  createCity: async (data: { name: string; nameAr: string }): Promise<City> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    return {
      id: Date.now().toString(),
      ...data,
      code: null,
      isActive: true,
    };
  },

  updateCity: async (id: string, data: { name: string; nameAr: string }): Promise<City> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    return {
      id: id,
      ...data,
      code: null,
      isActive: true,
    };
  },

  deleteCity: async (_id: string): Promise<void> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    // await apiClient.delete(`/settings/cities/${_id}`);
  },

  // Languages
  getLanguages: async (): Promise<Language[]> => {
    try {
      const response = await apiClient.get<LanguageApiResponse[]>('/Languages/GetAllLanguages');
      return response.map(mapLanguageResponse);
    } catch (error) {
      console.error('Error fetching languages:', error);
      throw error;
    }
  },

  createLanguage: async (data: { name: string; nameAr: string; code: string }): Promise<Language> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    return {
      id: Date.now().toString(),
      ...data,
      isActive: true,
    };
  },

  updateLanguage: async (id: string, data: { name: string; nameAr: string; code: string }): Promise<Language> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    return {
      id: id,
      ...data,
      isActive: true,
    };
  },

  deleteLanguage: async (_id: string): Promise<void> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    // await apiClient.delete(`/settings/languages/${_id}`);
  },

  // Nationalities
  getNationalities: async (): Promise<Nationality[]> => {
    try {
      const response = await apiClient.get<NationalityApiResponse[]>('/Nationalities/GetNationalities');
      return response.map(mapNationalityResponse);
    } catch (error) {
      console.error('Error fetching nationalities:', error);
      throw error;
    }
  },

  getNationalityById: async (id: string): Promise<NationalityApiResponse | null> => {
    try {
      const response = await apiClient.get<NationalityApiResponse>(`/Nationalities/GetNationalityById/${id}`);
      return response;
    } catch (error) {
      console.error('Error fetching nationality by id:', error);
      throw error;
    }
  },

  createNationality: async (data: { name: string; nameAr: string; code: string }): Promise<Nationality> => {
    try {
      // API expects: { name, code, isActive }
      const requestBody = {
        name: data.name,
        code: data.code,
        isActive: true,
      };
      const response = await apiClient.post<NationalityApiResponse>('/Nationalities/CreateNationality', requestBody);
      return mapNationalityResponse(response);
    } catch (error) {
      console.error('Error creating nationality:', error);
      throw error;
    }
  },

  updateNationality: async (id: string, data: { name: string; nameAr: string; code: string }): Promise<Nationality> => {
    try {
      // API expects: { name, code, isActive }
      const requestBody = {
        name: data.name,
        code: data.code,
        isActive: true, // You may want to get this from the existing nationality
      };
      const response = await apiClient.patch<NationalityApiResponse>(`/Nationalities/UpdateNationality/${id}`, requestBody);
      return mapNationalityResponse(response);
    } catch (error) {
      console.error('Error updating nationality:', error);
      throw error;
    }
  },

  deleteNationality: async (_id: string): Promise<void> => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    // await apiClient.delete(`/settings/nationalities/${_id}`);
  },
};
