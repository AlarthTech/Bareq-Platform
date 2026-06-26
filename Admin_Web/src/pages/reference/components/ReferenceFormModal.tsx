import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { FormModal } from '../../../shared/forms/FormModal';
import { Button } from '../../../shared/ui/Button';
import {
  createReferenceSchema,
  type CreateReferenceForm,
  type ReferenceItem,
  type UpdateReferenceForm,
} from '../../../types/reference.types';

interface ReferenceFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: CreateReferenceForm | UpdateReferenceForm) => Promise<void>;
  item?: ReferenceItem | null;
  isLoading?: boolean;
}

export function ReferenceFormModal({
  isOpen,
  onClose,
  onSubmit,
  item,
  isLoading,
}: ReferenceFormModalProps) {
  const isEdit = !!item;

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<CreateReferenceForm>({
    resolver: zodResolver(createReferenceSchema),
    defaultValues: { name: '', code: '', isActive: true },
  });

  useEffect(() => {
    if (isOpen) {
      reset(
        item
          ? { name: item.name, code: item.code ?? '', isActive: item.isActive }
          : { name: '', code: '', isActive: true }
      );
    }
  }, [isOpen, item, reset]);

  const submit = handleSubmit(async (data) => {
    await onSubmit(data);
    onClose();
  });

  return (
    <FormModal
      isOpen={isOpen}
      onClose={onClose}
      title={isEdit ? 'تعديل' : 'إضافة جديد'}
      footer={
        <>
          <Button type="button" variant="outline" onClick={onClose} disabled={isSubmitting || isLoading}>
            إلغاء
          </Button>
          <Button
            type="submit"
            form="reference-form"
            disabled={isSubmitting || isLoading}
            className="!bg-bareq-600 hover:!bg-bareq-700"
          >
            {isSubmitting || isLoading ? 'جاري الحفظ...' : 'حفظ'}
          </Button>
        </>
      }
    >
      <form id="reference-form" onSubmit={submit} className="space-y-4 text-right">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">الاسم *</label>
          <input
            {...register('name')}
            className="w-full border border-gray-200 rounded-lg px-3 py-2 focus:ring-2 focus:ring-bareq-500"
          />
          {errors.name && <p className="text-red-600 text-xs mt-1">{errors.name.message}</p>}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">الرمز</label>
          <input
            {...register('code')}
            maxLength={10}
            placeholder="اختياري — 10 أحرف كحد أقصى"
            className="w-full border border-gray-200 rounded-lg px-3 py-2 focus:ring-2 focus:ring-bareq-500"
          />
          {errors.code && <p className="text-red-600 text-xs mt-1">{errors.code.message}</p>}
        </div>

        <div className="flex items-center justify-between">
          <label htmlFor="isActive" className="text-sm font-medium text-gray-700">
            نشط
          </label>
          <input
            {...register('isActive')}
            id="isActive"
            type="checkbox"
            className="w-4 h-4 rounded border-gray-300 text-bareq-600 focus:ring-bareq-500"
          />
        </div>
      </form>
    </FormModal>
  );
}
