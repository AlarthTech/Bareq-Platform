import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { settingsApi } from '../../api';
import { PageHeader } from '../../../../shared/components/PageHeader';
import { Button } from '../../../../shared/ui/Button';
import { FormModal } from '../../../../shared/forms/FormModal';
import { ConfirmModal } from '../../../../shared/components/ConfirmModal';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import type { City, Language, Nationality } from '../../types';

const citySchema = z.object({
  name: z.string().min(1, 'Name is required'),
  nameAr: z.string().min(1, 'Arabic name is required'),
});

const languageSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  nameAr: z.string().min(1, 'Arabic name is required'),
  code: z.string().min(2, 'Code is required').max(2, 'Code must be 2 characters'),
});

const nationalitySchema = z.object({
  name: z.string().min(1, 'Name is required'),
  nameAr: z.string().min(1, 'Arabic name is required'),
  code: z.string().min(2, 'Code is required').max(2, 'Code must be 2 characters'),
});

type CityFormData = z.infer<typeof citySchema>;
type LanguageFormData = z.infer<typeof languageSchema>;
type NationalityFormData = z.infer<typeof nationalitySchema>;

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<'cities' | 'languages' | 'nationalities'>('cities');
  const [isCityModalOpen, setIsCityModalOpen] = useState(false);
  const [, setIsLanguageModalOpen] = useState(false);
  const [, setIsNationalityModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<City | Language | Nationality | null>(null);
  const [deleteItem, setDeleteItem] = useState<{ id: string; type: string } | null>(null);

  const queryClient = useQueryClient();

  const { data: cities } = useQuery({
    queryKey: ['settings', 'cities'],
    queryFn: settingsApi.getCities,
  });

  const { data: languages } = useQuery({
    queryKey: ['settings', 'languages'],
    queryFn: settingsApi.getLanguages,
  });

  const { data: nationalities } = useQuery({
    queryKey: ['settings', 'nationalities'],
    queryFn: settingsApi.getNationalities,
  });

  const cityForm = useForm<CityFormData>({
    resolver: zodResolver(citySchema),
  });

  const languageForm = useForm<LanguageFormData>({
    resolver: zodResolver(languageSchema),
  });

  const nationalityForm = useForm<NationalityFormData>({
    resolver: zodResolver(nationalitySchema),
  });

  const createCityMutation = useMutation({
    mutationFn: settingsApi.createCity,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings', 'cities'] });
      setIsCityModalOpen(false);
      cityForm.reset();
    },
  });

  const updateCityMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: CityFormData }) =>
      settingsApi.updateCity(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings', 'cities'] });
      setIsCityModalOpen(false);
      setEditingItem(null);
      cityForm.reset();
    },
  });

  const deleteCityMutation = useMutation({
    mutationFn: settingsApi.deleteCity,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings', 'cities'] });
      setDeleteItem(null);
    },
  });

  const handleEditCity = (city: City) => {
    setEditingItem(city);
    cityForm.reset({ name: city.name, nameAr: city.nameAr });
    setIsCityModalOpen(true);
  };

  const handleSubmitCity = (data: CityFormData) => {
    if (editingItem) {
      updateCityMutation.mutate({ id: editingItem.id, data });
    } else {
      createCityMutation.mutate(data);
    }
  };

  const tabs = [
    { id: 'cities', label: 'Cities' },
    { id: 'languages', label: 'Languages' },
    { id: 'nationalities', label: 'Nationalities' },
  ];

  return (
    <div>
      <PageHeader title="Settings" />

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="border-b border-gray-200">
          <nav className="flex -mb-px">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`px-6 py-4 text-sm font-medium border-b-2 ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </nav>
        </div>

        <div className="p-6">
          {activeTab === 'cities' && (
            <div>
              <div className="flex justify-end mb-4">
                <Button
                  onClick={() => {
                    setEditingItem(null);
                    cityForm.reset();
                    setIsCityModalOpen(true);
                  }}
                >
                  <Plus className="w-4 h-4 mr-2" />
                  Add City
                </Button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name (EN)</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name (AR)</th>
                      <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {cities?.map((city) => (
                      <tr key={city.id}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{city.name}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{city.nameAr}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <div className="flex justify-end gap-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleEditCity(city)}
                            >
                              <Pencil className="w-4 h-4" />
                            </Button>
                            <Button
                              variant="danger"
                              size="sm"
                              onClick={() => setDeleteItem({ id: city.id, type: 'city' })}
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'languages' && (
            <div>
              <div className="flex justify-end mb-4">
                <Button
                  onClick={() => {
                    setEditingItem(null);
                    languageForm.reset();
                    setIsLanguageModalOpen(true);
                  }}
                >
                  <Plus className="w-4 h-4 mr-2" />
                  Add Language
                </Button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name (EN)</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name (AR)</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Code</th>
                      <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {languages?.map((lang) => (
                      <tr key={lang.id}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{lang.name}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{lang.nameAr}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{lang.code || 'N/A'}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <div className="flex justify-end gap-2">
                            <Button variant="outline" size="sm">
                              <Pencil className="w-4 h-4" />
                            </Button>
                            <Button variant="danger" size="sm">
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'nationalities' && (
            <div>
              <div className="flex justify-end mb-4">
                <Button
                  onClick={() => {
                    setEditingItem(null);
                    nationalityForm.reset();
                    setIsNationalityModalOpen(true);
                  }}
                >
                  <Plus className="w-4 h-4 mr-2" />
                  Add Nationality
                </Button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name (EN)</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name (AR)</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Code</th>
                      <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {nationalities?.map((nat) => (
                      <tr key={nat.id}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{nat.name}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{nat.nameAr}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{nat.code || 'N/A'}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <div className="flex justify-end gap-2">
                            <Button variant="outline" size="sm">
                              <Pencil className="w-4 h-4" />
                            </Button>
                            <Button variant="danger" size="sm">
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* City Form Modal */}
      <FormModal
        isOpen={isCityModalOpen}
        onClose={() => {
          setIsCityModalOpen(false);
          setEditingItem(null);
          cityForm.reset();
        }}
        title={editingItem ? 'Edit City' : 'Add City'}
        footer={
          <>
            <Button
              variant="outline"
              onClick={() => {
                setIsCityModalOpen(false);
                setEditingItem(null);
                cityForm.reset();
              }}
            >
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={cityForm.handleSubmit(handleSubmitCity)}
              disabled={createCityMutation.isPending || updateCityMutation.isPending}
            >
              {editingItem ? 'Update' : 'Create'}
            </Button>
          </>
        }
      >
        <form className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Name (English)
            </label>
            <input
              {...cityForm.register('name')}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
            {cityForm.formState.errors.name && (
              <p className="mt-1 text-sm text-red-600">{cityForm.formState.errors.name.message}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Name (Arabic)
            </label>
            <input
              {...cityForm.register('nameAr')}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
            {cityForm.formState.errors.nameAr && (
              <p className="mt-1 text-sm text-red-600">{cityForm.formState.errors.nameAr.message}</p>
            )}
          </div>
        </form>
      </FormModal>

      {/* Delete Confirmation Modal */}
      <ConfirmModal
        isOpen={!!deleteItem}
        onClose={() => setDeleteItem(null)}
        onConfirm={() => {
          if (deleteItem?.type === 'city') {
            deleteCityMutation.mutate(deleteItem.id);
          }
        }}
        title="Delete Item"
        message="Are you sure you want to delete this item? This action cannot be undone."
        isLoading={deleteCityMutation.isPending}
      />
    </div>
  );
}
