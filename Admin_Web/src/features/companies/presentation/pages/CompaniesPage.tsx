import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Building2, Clock, Trash2 } from 'lucide-react';
import { companiesApi } from '../../api';
import { DataTable } from '../../../../shared/tables/DataTable';
import { StatusBadge } from '../../../../shared/components/StatusBadge';
import { PageHeader } from '../../../../shared/components/PageHeader';
import { ConfirmModal } from '../../../../shared/components/ConfirmModal';
import { OwnerProfileModal } from '../components/OwnerProfileModal';
import { Button } from '../../../../shared/ui/Button';
import { formatDate, classNames } from '../../../../core/utils';
import { PAGINATION } from '../../../../core/constants';
import { useDebounce } from '../../../../core/hooks/useDebounce';
import type { Company } from '../../types';

export default function CompaniesPage() {
  const [page, setPage] = useState<number>(PAGINATION.DEFAULT_PAGE);
  const [pageSize, setPageSize] = useState<number>(PAGINATION.DEFAULT_PAGE_SIZE);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string | undefined>(undefined);
  const [selectedCompany, setSelectedCompany] = useState<{ id: string; action: 'approve' | 'reject' | 'deactivate' | 'delete' } | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedOwnerId, setSelectedOwnerId] = useState<string | null>(null);
  const [isOwnerModalOpen, setIsOwnerModalOpen] = useState(false);

  const debouncedSearch = useDebounce(searchQuery, 500);
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['companies', page, pageSize, debouncedSearch, statusFilter],
    queryFn: () => companiesApi.getCompanies({ page, pageSize, search: debouncedSearch, status: statusFilter }),
  });

  const { data: counts } = useQuery({
    queryKey: ['companies', 'counts'],
    queryFn: companiesApi.getCompanyCounts,
  });

  const { data: owner, isLoading: isLoadingOwner } = useQuery({
    queryKey: ['owner', selectedOwnerId],
    queryFn: () => companiesApi.getOwnerById(selectedOwnerId!),
    enabled: !!selectedOwnerId && isOwnerModalOpen,
  });

  const approveMutation = useMutation({
    mutationFn: companiesApi.approveCompany,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setIsModalOpen(false);
      setSelectedCompany(null);
    },
  });

  const rejectMutation = useMutation({
    mutationFn: companiesApi.rejectCompany,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setIsModalOpen(false);
      setSelectedCompany(null);
    },
  });

  const deactivateMutation = useMutation({
    mutationFn: companiesApi.deactivateCompany,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setIsModalOpen(false);
      setSelectedCompany(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: companiesApi.deleteCompany,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setIsModalOpen(false);
      setSelectedCompany(null);
    },
  });

  const handleApprove = (company: Company) => {
    setSelectedCompany({ id: company.id, action: 'approve' });
    setIsModalOpen(true);
  };

  const handleReject = (company: Company) => {
    setSelectedCompany({ id: company.id, action: 'reject' });
    setIsModalOpen(true);
  };

  const handleDeactivate = (company: Company) => {
    setSelectedCompany({ id: company.id, action: 'deactivate' });
    setIsModalOpen(true);
  };

  const handleDelete = (company: Company) => {
    setSelectedCompany({ id: company.id, action: 'delete' });
    setIsModalOpen(true);
  };

  const handleConfirm = () => {
    if (selectedCompany) {
      if (selectedCompany.action === 'approve') {
        approveMutation.mutate(selectedCompany.id);
      } else if (selectedCompany.action === 'reject') {
        rejectMutation.mutate(selectedCompany.id);
      } else if (selectedCompany.action === 'deactivate') {
        deactivateMutation.mutate(selectedCompany.id);
      } else if (selectedCompany.action === 'delete') {
        deleteMutation.mutate(selectedCompany.id);
      }
    }
  };

  const handleStatusFilter = (status: string | undefined) => {
    setStatusFilter(status);
    setPage(1); // Reset to first page when filtering
  };

  const handleOwnerClick = (company: Company) => {
    if (company.ownerId) {
      setSelectedOwnerId(company.ownerId);
      setIsOwnerModalOpen(true);
    }
  };

  const columns = [
    {
      key: 'name',
      header: 'Company Name',
      render: (item: Company) => (
        <div>
          <div className="font-medium">{item.name}</div>
          <div className="text-xs text-gray-500">{item.nameAr}</div>
        </div>
      ),
    },
    {
      key: 'ownerName',
      header: 'Owner',
      render: (item: Company) => (
        <div>
          {item.ownerId ? (
            <button
              onClick={() => handleOwnerClick(item)}
              className="text-left hover:underline"
            >
              <div className="font-medium text-blue-600 hover:text-blue-800">{item.ownerName}</div>
              <div className="text-xs text-gray-500">{item.ownerEmail}</div>
            </button>
          ) : (
            <div>
              <div className="font-medium">{item.ownerName}</div>
              <div className="text-xs text-gray-500">{item.ownerEmail}</div>
            </div>
          )}
        </div>
      ),
    },
    {
      key: 'phone',
      header: 'Phone',
    },
    {
      key: 'city',
      header: 'City',
    },
    {
      key: 'status',
      header: 'Status',
      render: (item: Company) => <StatusBadge status={item.status} />,
    },
    {
      key: 'createdAt',
      header: 'Created At',
      render: (item: Company) => formatDate(item.createdAt),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (item: Company) => (
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
          <Button
            variant="danger"
            size="sm"
            onClick={() => handleDelete(item)}
            title="Delete Company"
          >
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <div>
      <PageHeader title="Companies" />

      {/* Status Filter Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
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
              <p className="text-sm font-medium text-gray-600 mb-1">Active Companies</p>
              <p className="text-3xl font-bold text-gray-900">{counts?.active || 0}</p>
            </div>
            <div className="flex items-center justify-center w-12 h-12 bg-green-50 rounded-lg">
              <Building2 className="w-6 h-6 text-green-600" />
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
              <p className="text-sm font-medium text-gray-600 mb-1">Pending Companies</p>
              <p className="text-3xl font-bold text-gray-900">{counts?.pending || 0}</p>
            </div>
            <div className="flex items-center justify-center w-12 h-12 bg-yellow-50 rounded-lg">
              <Clock className="w-6 h-6 text-yellow-600" />
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
        searchPlaceholder="Search companies..."
        emptyMessage="No companies found"
      />

      <ConfirmModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedCompany(null);
        }}
        onConfirm={handleConfirm}
        title={
          selectedCompany?.action === 'approve'
            ? 'Approve Company'
            : selectedCompany?.action === 'reject'
            ? 'Reject Company'
            : selectedCompany?.action === 'deactivate'
            ? 'Deactivate Company'
            : 'Delete Company'
        }
        message={
          selectedCompany?.action === 'approve'
            ? 'Are you sure you want to approve this company?'
            : selectedCompany?.action === 'reject'
            ? 'Are you sure you want to reject this company?'
            : selectedCompany?.action === 'deactivate'
            ? 'Are you sure you want to deactivate this company?'
            : 'Are you sure you want to delete this company? This action cannot be undone.'
        }
        variant={
          selectedCompany?.action === 'approve'
            ? 'info'
            : selectedCompany?.action === 'deactivate'
            ? 'warning'
            : 'danger'
        }
        isLoading={approveMutation.isPending || rejectMutation.isPending || deactivateMutation.isPending || deleteMutation.isPending}
      />

      <OwnerProfileModal
        isOpen={isOwnerModalOpen}
        onClose={() => {
          setIsOwnerModalOpen(false);
          setSelectedOwnerId(null);
        }}
        owner={owner || null}
        isLoading={isLoadingOwner}
      />
    </div>
  );
}
