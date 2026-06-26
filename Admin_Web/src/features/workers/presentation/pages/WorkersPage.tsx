import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UserCheck, Clock, AlertTriangle, AlertCircle } from 'lucide-react';
import { workersApi } from '../../api';
import { companiesApi } from '../../../companies/api';
import { DataTable } from '../../../../shared/tables/DataTable';
import { StatusBadge } from '../../../../shared/components/StatusBadge';
import { PageHeader } from '../../../../shared/components/PageHeader';
import { ConfirmModal } from '../../../../shared/components/ConfirmModal';
import { CompanyProfileModal } from '../../../companies/presentation/components/CompanyProfileModal';
import { Button } from '../../../../shared/ui/Button';
import { formatDate, classNames } from '../../../../core/utils';
import { PAGINATION } from '../../../../core/constants';
import { useDebounce } from '../../../../core/hooks/useDebounce';
import type { Worker } from '../../types';

export default function WorkersPage() {
  const [page, setPage] = useState<number>(PAGINATION.DEFAULT_PAGE);
  const [pageSize, setPageSize] = useState<number>(PAGINATION.DEFAULT_PAGE_SIZE);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string | undefined>(undefined);
  const [healthCertFilter, setHealthCertFilter] = useState<string | undefined>(undefined);
  const [selectedWorker, setSelectedWorker] = useState<{ id: string; action: 'approve' | 'reject' | 'deactivate' } | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedCompanyId, setSelectedCompanyId] = useState<number | null>(null);
  const [isCompanyModalOpen, setIsCompanyModalOpen] = useState(false);

  const debouncedSearch = useDebounce(searchQuery, 500);
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['workers', page, pageSize, debouncedSearch, statusFilter, healthCertFilter],
    queryFn: () =>
      workersApi.getWorkers({
        page,
        pageSize,
        search: debouncedSearch,
        status: statusFilter,
        healthCertificateStatus: healthCertFilter,
      }),
  });

  const { data: counts } = useQuery({
    queryKey: ['workers', 'counts'],
    queryFn: workersApi.getWorkerCounts,
  });

  const { data: company, isLoading: isLoadingCompany } = useQuery({
    queryKey: ['company', selectedCompanyId],
    queryFn: () => companiesApi.getCompanyById(selectedCompanyId!),
    enabled: !!selectedCompanyId && isCompanyModalOpen,
  });

  const approveMutation = useMutation({
    mutationFn: workersApi.approveWorker,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workers'] });
      setIsModalOpen(false);
      setSelectedWorker(null);
    },
  });

  const rejectMutation = useMutation({
    mutationFn: workersApi.rejectWorker,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workers'] });
      setIsModalOpen(false);
      setSelectedWorker(null);
    },
  });

  const deactivateMutation = useMutation({
    mutationFn: workersApi.deactivateWorker,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workers'] });
      setIsModalOpen(false);
      setSelectedWorker(null);
    },
  });

  const handleApprove = (worker: Worker) => {
    setSelectedWorker({ id: worker.id, action: 'approve' });
    setIsModalOpen(true);
  };

  const handleReject = (worker: Worker) => {
    setSelectedWorker({ id: worker.id, action: 'reject' });
    setIsModalOpen(true);
  };

  const handleDeactivate = (worker: Worker) => {
    setSelectedWorker({ id: worker.id, action: 'deactivate' });
    setIsModalOpen(true);
  };

  const handleConfirm = () => {
    if (selectedWorker) {
      if (selectedWorker.action === 'approve') {
        approveMutation.mutate(selectedWorker.id);
      } else if (selectedWorker.action === 'reject') {
        rejectMutation.mutate(selectedWorker.id);
      } else if (selectedWorker.action === 'deactivate') {
        deactivateMutation.mutate(selectedWorker.id);
      }
    }
  };

  const handleStatusFilter = (status: string | undefined) => {
    setStatusFilter(status);
    setHealthCertFilter(undefined); // Clear health cert filter when filtering by status
    setPage(1); // Reset to first page when filtering
  };

  const handleHealthCertFilter = (status: string | undefined) => {
    setHealthCertFilter(status);
    setStatusFilter(undefined); // Clear status filter when filtering by health cert
    setPage(1); // Reset to first page when filtering
  };

  const handleCompanyClick = (worker: Worker) => {
    if (worker.companyId) {
      setSelectedCompanyId(worker.companyId);
      setIsCompanyModalOpen(true);
    }
  };

  const columns = [
    {
      key: 'name',
      header: 'Name',
      render: (item: Worker) => (
        <div>
          <div className="font-medium">{item.name}</div>
          <div className="text-xs text-gray-500">{item.nameAr}</div>
        </div>
      ),
    },
    {
      key: 'nationality',
      header: 'Nationality',
    },
    {
      key: 'companyName',
      header: 'Company',
      render: (item: Worker) => (
        <div>
          {item.companyId ? (
            <button
              onClick={() => handleCompanyClick(item)}
              className="text-blue-600 hover:text-blue-800 hover:underline"
            >
              {item.companyName}
            </button>
          ) : (
            <span>{item.companyName}</span>
          )}
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (item: Worker) => <StatusBadge status={item.status} />,
    },
    {
      key: 'healthCertificateStatus',
      header: 'Health Certificate',
      render: (item: Worker) => (
        <div>
          <StatusBadge status={item.healthCertificateStatus} />
          {item.healthCertificateExpiry && (
            <div className="text-xs text-gray-500 mt-1">
              Expires: {formatDate(item.healthCertificateExpiry)}
            </div>
          )}
        </div>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (item: Worker) => (
        <div className="flex gap-2">
          {item.status === 'pending' && (
            <>
              <Button
                variant="primary"
                size="sm"
                onClick={() => handleApprove(item)}
              >
                Approve
              </Button>
              <Button
                variant="danger"
                size="sm"
                onClick={() => handleReject(item)}
              >
                Reject
              </Button>
            </>
          )}
          {item.status === 'active' && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => handleDeactivate(item)}
            >
              Deactivate
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div>
      <PageHeader title="Workers" />

      {/* Status Filter Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <button
          onClick={() => handleStatusFilter(statusFilter === 'active' ? undefined : 'active')}
          className={classNames(
            'bg-white rounded-lg shadow-sm border p-6 text-left transition-all hover:shadow-md',
            statusFilter === 'active'
              ? 'border-blue-500 ring-2 ring-blue-200'
              : 'border-gray-200 hover:border-gray-300'
          )}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 mb-1">Active Workers</p>
              <p className="text-3xl font-bold text-gray-900">{counts?.active || 0}</p>
            </div>
            <div className="flex items-center justify-center w-12 h-12 bg-green-50 rounded-lg">
              <UserCheck className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </button>

        <button
          onClick={() => handleStatusFilter(statusFilter === 'pending' ? undefined : 'pending')}
          className={classNames(
            'bg-white rounded-lg shadow-sm border p-6 text-left transition-all hover:shadow-md',
            statusFilter === 'pending'
              ? 'border-blue-500 ring-2 ring-blue-200'
              : 'border-gray-200 hover:border-gray-300'
          )}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 mb-1">Pending Workers</p>
              <p className="text-3xl font-bold text-gray-900">{counts?.pending || 0}</p>
            </div>
            <div className="flex items-center justify-center w-12 h-12 bg-yellow-50 rounded-lg">
              <Clock className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
        </button>

        <button
          onClick={() => handleHealthCertFilter(healthCertFilter === 'expired' ? undefined : 'expired')}
          className={classNames(
            'bg-white rounded-lg shadow-sm border p-6 text-left transition-all hover:shadow-md',
            healthCertFilter === 'expired'
              ? 'border-blue-500 ring-2 ring-blue-200'
              : 'border-gray-200 hover:border-gray-300'
          )}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 mb-1">Expired Health Certificate</p>
              <p className="text-3xl font-bold text-gray-900">{counts?.expiredHealthCert || 0}</p>
            </div>
            <div className="flex items-center justify-center w-12 h-12 bg-red-50 rounded-lg">
              <AlertCircle className="w-6 h-6 text-red-600" />
            </div>
          </div>
        </button>

        <button
          onClick={() => handleHealthCertFilter(healthCertFilter === 'almost_expired' ? undefined : 'almost_expired')}
          className={classNames(
            'bg-white rounded-lg shadow-sm border p-6 text-left transition-all hover:shadow-md',
            healthCertFilter === 'almost_expired'
              ? 'border-blue-500 ring-2 ring-blue-200'
              : 'border-gray-200 hover:border-gray-300'
          )}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 mb-1">Almost Expired Health Certificate</p>
              <p className="text-3xl font-bold text-gray-900">{counts?.almostExpiredHealthCert || 0}</p>
            </div>
            <div className="flex items-center justify-center w-12 h-12 bg-orange-50 rounded-lg">
              <AlertTriangle className="w-6 h-6 text-orange-600" />
            </div>
          </div>
        </button>
      </div>

      <DataTable
        data={data?.data || []}
        columns={columns}
        isLoading={isLoading}
        pagination={data?.pagination}
        onPageChange={setPage}
        onPageSizeChange={(newSize) => {
          setPageSize(newSize);
          setPage(1);
        }}
        onSearch={setSearchQuery}
        searchPlaceholder="Search workers..."
        emptyMessage="No workers found"
      />

      <ConfirmModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedWorker(null);
        }}
        onConfirm={handleConfirm}
        title={
          selectedWorker?.action === 'approve'
            ? 'Approve Worker'
            : selectedWorker?.action === 'reject'
            ? 'Reject Worker'
            : 'Deactivate Worker'
        }
        message={
          selectedWorker?.action === 'approve'
            ? 'Are you sure you want to approve this worker?'
            : selectedWorker?.action === 'reject'
            ? 'Are you sure you want to reject this worker?'
            : 'Are you sure you want to deactivate this worker?'
        }
        variant={
          selectedWorker?.action === 'approve'
            ? 'info'
            : selectedWorker?.action === 'deactivate'
            ? 'warning'
            : 'danger'
        }
        isLoading={approveMutation.isPending || rejectMutation.isPending || deactivateMutation.isPending}
      />

      <CompanyProfileModal
        isOpen={isCompanyModalOpen}
        onClose={() => {
          setIsCompanyModalOpen(false);
          setSelectedCompanyId(null);
        }}
        company={company || null}
        isLoading={isLoadingCompany}
      />
    </div>
  );
}
