import { Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { X, Building2, Mail, Phone, MapPin, Calendar } from 'lucide-react';
import { formatDate } from '../../../../core/utils';
import { StatusBadge } from '../../../../shared/components/StatusBadge';
import type { CompanyApiResponse } from '../../types';

interface CompanyProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  company: CompanyApiResponse | null;
  isLoading?: boolean;
}

export const CompanyProfileModal = ({ isOpen, onClose, company, isLoading }: CompanyProfileModalProps) => {
  const companyName = company?.name || company?.fullName || 'Unknown Company';
  const companyNameAr = company?.nameAr || companyName;
  const status = company?.isVerified === true ? 'active' : company?.isVerified === false ? 'pending' : 'inactive';

  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={onClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black bg-opacity-25" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4 text-center">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-md transform overflow-hidden rounded-lg bg-white p-6 text-left align-middle shadow-xl transition-all">
                <div className="flex items-center justify-between mb-4">
                  <Dialog.Title as="h3" className="text-lg font-medium leading-6 text-gray-900">
                    Company Profile
                  </Dialog.Title>
                  <button
                    onClick={onClose}
                    className="text-gray-400 hover:text-gray-500"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                <div className="mt-4">
                  {isLoading ? (
                    <div className="flex items-center justify-center py-8">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                    </div>
                  ) : company ? (
                    <div className="space-y-4">
                      <div className="flex items-center gap-3">
                        <div className="flex-shrink-0">
                          <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center">
                            <Building2 className="w-8 h-8 text-blue-600" />
                          </div>
                        </div>
                        <div className="flex-1">
                          <h4 className="text-xl font-semibold text-gray-900">{companyName}</h4>
                          {companyNameAr && companyNameAr !== companyName && (
                            <p className="text-sm text-gray-500">{companyNameAr}</p>
                          )}
                          <div className="mt-1">
                            <StatusBadge status={status} />
                          </div>
                        </div>
                      </div>

                      <div className="border-t border-gray-200 pt-4 space-y-3">
                        {company.email && (
                          <div className="flex items-start gap-3">
                            <Mail className="w-5 h-5 text-gray-400 mt-0.5" />
                            <div>
                              <p className="text-sm font-medium text-gray-500">Email</p>
                              <p className="text-sm text-gray-900">{company.email}</p>
                            </div>
                          </div>
                        )}

                        {company.phone && (
                          <div className="flex items-start gap-3">
                            <Phone className="w-5 h-5 text-gray-400 mt-0.5" />
                            <div>
                              <p className="text-sm font-medium text-gray-500">Phone</p>
                              <p className="text-sm text-gray-900">{company.phone}</p>
                            </div>
                          </div>
                        )}

                        {company.cityName && (
                          <div className="flex items-start gap-3">
                            <MapPin className="w-5 h-5 text-gray-400 mt-0.5" />
                            <div>
                              <p className="text-sm font-medium text-gray-500">City</p>
                              <p className="text-sm text-gray-900">{company.cityName}</p>
                            </div>
                          </div>
                        )}

                        {company.createdAt && (
                          <div className="flex items-start gap-3">
                            <Calendar className="w-5 h-5 text-gray-400 mt-0.5" />
                            <div>
                              <p className="text-sm font-medium text-gray-500">Created At</p>
                              <p className="text-sm text-gray-900">{formatDate(company.createdAt)}</p>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div className="text-center py-8">
                      <p className="text-gray-500">Company information not available</p>
                    </div>
                  )}
                </div>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
};
