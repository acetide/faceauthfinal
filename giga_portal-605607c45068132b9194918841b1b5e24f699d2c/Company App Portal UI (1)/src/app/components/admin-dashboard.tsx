import { Card } from '@/app/components/ui/card';
import { Button } from '@/app/components/ui/button';
import { Badge } from '@/app/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/app/components/ui/table';
import { Check, X, Clock, FileText, Megaphone, Plus } from 'lucide-react';
import { LeaveRequestData } from './leave-request';
import { Comment } from './homepage';

export interface Announcement {
  id: string;
  title: string;
  message: string;
  date: string;
  type: 'info' | 'warning' | 'success';
  imageUrl?: string;
  comments: Comment[];
}

interface AdminDashboardProps {
  leaveRequests: LeaveRequestData[];
  onApprove: (id: string) => void;
  onReject: (id: string) => void;
  announcements: Announcement[];
  onCreateAnnouncement: () => void;
}

export function AdminDashboard({ leaveRequests, onApprove, onReject, announcements, onCreateAnnouncement }: AdminDashboardProps) {
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'approved':
        return <Badge variant="default" className="bg-green-500">Approved</Badge>;
      case 'rejected':
        return <Badge variant="destructive">Rejected</Badge>;
      default:
        return <Badge variant="secondary">Pending</Badge>;
    }
  };

  const getLeaveTypeLabel = (type: string) => {
    switch (type) {
      case 'official':
        return 'Official Leave';
      case 'sick':
        return 'Sick Leave';
      case 'paid':
        return 'Paid Leave';
      default:
        return type;
    }
  };

  const pendingRequests = leaveRequests.filter(req => req.status === 'pending');
  const processedRequests = leaveRequests.filter(req => req.status !== 'pending');

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold mb-2">Admin Dashboard</h1>
        <p className="text-gray-600">Review and manage employee leave requests</p>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="p-6">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-lg" style={{ backgroundColor: '#90CFE0' }}>
              <Clock className="w-6 h-6" style={{ color: '#424094' }} />
            </div>
            <div>
              <p className="text-sm text-gray-600">Pending Requests</p>
              <p className="text-2xl font-bold">{pendingRequests.length}</p>
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-lg" style={{ backgroundColor: '#2699C7' }}>
              <Check className="w-6 h-6 text-white" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Approved</p>
              <p className="text-2xl font-bold">
                {leaveRequests.filter(req => req.status === 'approved').length}
              </p>
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-lg" style={{ backgroundColor: '#D5E2E6' }}>
              <X className="w-6 h-6" style={{ color: '#424094' }} />
            </div>
            <div>
              <p className="text-sm text-gray-600">Rejected</p>
              <p className="text-2xl font-bold">
                {leaveRequests.filter(req => req.status === 'rejected').length}
              </p>
            </div>
          </div>
        </Card>
      </div>

      {/* Pending Requests */}
      <Card className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <FileText className="w-5 h-5" />
          <h2 className="text-xl font-semibold">Pending Leave Requests</h2>
        </div>

        {pendingRequests.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <Clock className="w-12 h-12 mx-auto mb-2 opacity-50" />
            <p>No pending requests</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Employee</TableHead>
                  <TableHead>Leave Type</TableHead>
                  <TableHead>Start Date</TableHead>
                  <TableHead>End Date</TableHead>
                  <TableHead>Reason</TableHead>
                  <TableHead>Submitted</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pendingRequests.map((request) => (
                  <TableRow key={request.id}>
                    <TableCell className="font-medium">{request.employeeName}</TableCell>
                    <TableCell>
                      <Badge variant="outline">{getLeaveTypeLabel(request.leaveType)}</Badge>
                    </TableCell>
                    <TableCell>{request.startDate}</TableCell>
                    <TableCell>{request.endDate}</TableCell>
                    <TableCell className="max-w-xs truncate">{request.reason}</TableCell>
                    <TableCell className="text-sm text-gray-500">{request.submittedDate}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex gap-2 justify-end">
                        <Button
                          size="sm"
                          variant="default"
                          onClick={() => onApprove(request.id)}
                          className="bg-green-600 hover:bg-green-700"
                        >
                          <Check className="w-4 h-4 mr-1" />
                          Approve
                        </Button>
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => onReject(request.id)}
                        >
                          <X className="w-4 h-4 mr-1" />
                          Reject
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </Card>

      {/* Processed Requests History */}
      <Card className="p-6">
        <h2 className="text-xl font-semibold mb-4">Request History</h2>

        {processedRequests.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <FileText className="w-12 h-12 mx-auto mb-2 opacity-50" />
            <p>No processed requests yet</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Employee</TableHead>
                  <TableHead>Leave Type</TableHead>
                  <TableHead>Start Date</TableHead>
                  <TableHead>End Date</TableHead>
                  <TableHead>Reason</TableHead>
                  <TableHead>Submitted</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {processedRequests.map((request) => (
                  <TableRow key={request.id}>
                    <TableCell className="font-medium">{request.employeeName}</TableCell>
                    <TableCell>
                      <Badge variant="outline">{getLeaveTypeLabel(request.leaveType)}</Badge>
                    </TableCell>
                    <TableCell>{request.startDate}</TableCell>
                    <TableCell>{request.endDate}</TableCell>
                    <TableCell className="max-w-xs truncate">{request.reason}</TableCell>
                    <TableCell className="text-sm text-gray-500">{request.submittedDate}</TableCell>
                    <TableCell>{getStatusBadge(request.status)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </Card>

      {/* Announcements */}
      <Card className="p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Megaphone className="w-5 h-5" />
            <h2 className="text-xl font-semibold">Announcements Management</h2>
          </div>
          <Button onClick={onCreateAnnouncement}>
            <Plus className="w-4 h-4 mr-2" />
            Create Announcement
          </Button>
        </div>

        {announcements.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <Megaphone className="w-12 h-12 mx-auto mb-2 opacity-50" />
            <p>No announcements yet</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Title</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Comments</TableHead>
                  <TableHead>Has Image</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {announcements.map((announcement) => (
                  <TableRow key={announcement.id}>
                    <TableCell className="font-medium">{announcement.title}</TableCell>
                    <TableCell>
                      <Badge variant="outline">{announcement.type}</Badge>
                    </TableCell>
                    <TableCell className="text-sm text-gray-500">{announcement.date}</TableCell>
                    <TableCell>{announcement.comments.length}</TableCell>
                    <TableCell>{announcement.imageUrl ? 'Yes' : 'No'}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </Card>
    </div>
  );
}