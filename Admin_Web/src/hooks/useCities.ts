import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { citiesApi } from '../api/reference.api';
import type { CreateReferenceItem, UpdateReferenceItem } from '../types/reference.types';

export function useCities(page: number, pageSize = 20) {
  return useQuery({
    queryKey: ['cities', page, pageSize],
    queryFn: () => citiesApi.list(page, pageSize),
  });
}

export function useCreateCity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateReferenceItem) => citiesApi.create(data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cities'] }),
  });
}

export function useUpdateCity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateReferenceItem }) =>
      citiesApi.update(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cities'] }),
  });
}

export function useDeleteCity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => citiesApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cities'] }),
  });
}
