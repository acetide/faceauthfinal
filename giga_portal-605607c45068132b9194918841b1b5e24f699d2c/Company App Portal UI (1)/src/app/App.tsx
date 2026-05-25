import { useState } from 'react';
import { HomePage, Comment } from '@/app/components/homepage';
import { LeaveRequest, LeaveRequestData } from '@/app/components/leave-request';
import { AdminDashboard, Announcement } from '@/app/components/admin-dashboard';
import { AnnouncementForm, AnnouncementFormData } from '@/app/components/announcement-form';
import { EmployeeChat } from '@/app/components/employee-chat';
import { Button } from '@/app/components/ui/button';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/app/components/ui/tabs';
import { User, Shield, Building2 } from 'lucide-react';
import { Toaster } from '@/app/components/ui/sonner';
import { toast } from 'sonner';

export default function App() {
  const [activeTab, setActiveTab] = useState<'employee' | 'admin'>('employee');
  const [isLeaveRequestOpen, setIsLeaveRequestOpen] = useState(false);
  const [isAnnouncementFormOpen, setIsAnnouncementFormOpen] = useState(false);
  
  const [leaveRequests, setLeaveRequests] = useState<LeaveRequestData[]>([
    {
      id: '1',
      employeeName: 'Fitri Sutrisno',
      leaveType: 'sick',
      startDate: '2026-01-28',
      endDate: '2026-01-30',
      reason: 'Doctor appointment and medical checkup',
      status: 'pending',
      submittedDate: '2026-01-22',
    },
    {
      id: '2',
      employeeName: 'Ahmad Saleh',
      leaveType: 'paid',
      startDate: '2026-02-10',
      endDate: '2026-02-14',
      reason: 'Family vacation',
      status: 'approved',
      submittedDate: '2026-01-20',
    },
  ]);

  const [announcements, setAnnouncements] = useState<Announcement[]>([
    {
      id: '1',
      title: 'Office Closure Notice',
      message: 'The office will be closed on January 30th for maintenance work.',
      date: '2026-01-20',
      type: 'warning',
      comments: [
        {
          id: 'c1',
          authorName: 'Ahmad Saleh',
          text: 'Thanks for the heads up!',
          timestamp: '2026-01-20 10:30 AM',
        },
        {
          id: 'c1b',
          authorName: 'Robert Sutadi',
          text: 'Will we be able to work from home that day?',
          timestamp: '2026-01-20 11:15 AM',
        },
        {
          id: 'c1c',
          authorName: 'Fitri Sutrisno',
          text: 'Good to know. I\'ll plan accordingly.',
          timestamp: '2026-01-20 2:45 PM',
        },
      ],
    },
    {
      id: '2',
      title: 'New Year Celebration',
      message: 'Join us for the company New Year celebration on February 5th at 6 PM!',
      date: '2026-01-18',
      type: 'success',
      imageUrl: 'https://images.unsplash.com/photo-1758691737584-a8f17fb34475?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxidXNpbmVzcyUyMGNlbGVicmF0aW9uJTIwc3VjY2Vzc3xlbnwxfHx8fDE3NjkxMzgwMTN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
      comments: [
        {
          id: 'c2',
          authorName: 'Fitri Sutrisno',
          text: 'Looking forward to it!',
          timestamp: '2026-01-18 2:15 PM',
        },
        {
          id: 'c3',
          authorName: 'Samuel Panggabean',
          text: 'Can we bring our families?',
          timestamp: '2026-01-18 3:45 PM',
        },
        {
          id: 'c3b',
          authorName: 'Ahmad Saleh',
          text: 'This sounds amazing! Count me in 🎉',
          timestamp: '2026-01-18 4:20 PM',
        },
        {
          id: 'c3c',
          authorName: 'Robert Sutadi',
          text: 'Will there be vegetarian options available?',
          timestamp: '2026-01-18 5:30 PM',
        },
      ],
    },
    {
      id: '3',
      title: 'System Update',
      message: 'Our HR system will undergo maintenance this weekend. Please submit your timesheets by Friday.',
      date: '2026-01-15',
      type: 'info',
      comments: [
        {
          id: 'c4',
          authorName: 'Robert Sutadi',
          text: 'Already submitted mine. Thanks!',
          timestamp: '2026-01-15 9:00 AM',
        },
      ],
    },
  ]);

  // Mock employee data
  const employeeData = {
    name: 'Herman Hartono',
    wage: 'Rp 65,000,000/month',
    absentDays: 2,
  };

  const handleLeaveRequestSubmit = (request: Omit<LeaveRequestData, 'id' | 'status' | 'submittedDate'>) => {
    const newRequest: LeaveRequestData = {
      ...request,
      id: Date.now().toString(),
      status: 'pending',
      submittedDate: new Date().toLocaleDateString('en-CA'),
    };

    setLeaveRequests([...leaveRequests, newRequest]);
    toast.success('Leave request submitted successfully!', {
      description: 'Your manager will review your request.',
    });
  };

  const handleApprove = (id: string) => {
    setLeaveRequests(
      leaveRequests.map((req) =>
        req.id === id ? { ...req, status: 'approved' as const } : req
      )
    );
    toast.success('Leave request approved!');
  };

  const handleReject = (id: string) => {
    setLeaveRequests(
      leaveRequests.map((req) =>
        req.id === id ? { ...req, status: 'rejected' as const } : req
      )
    );
    toast.error('Leave request rejected');
  };

  const handleAnnouncementSubmit = (announcementData: AnnouncementFormData) => {
    const newAnnouncement: Announcement = {
      id: Date.now().toString(),
      ...announcementData,
      date: new Date().toLocaleDateString('en-CA'),
      comments: [],
    };

    setAnnouncements([newAnnouncement, ...announcements]);
    toast.success('Announcement created successfully!', {
      description: 'All employees can now see this announcement.',
    });
  };

  const handleAddComment = (announcementId: string, commentText: string) => {
    const newComment: Comment = {
      id: Date.now().toString(),
      authorName: employeeData.name,
      text: commentText,
      timestamp: new Date().toLocaleString('en-US', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      }),
    };

    setAnnouncements(
      announcements.map((announcement) =>
        announcement.id === announcementId
          ? { ...announcement, comments: [...announcement.comments, newComment] }
          : announcement
      )
    );

    toast.success('Comment added!');
  };

  return (
    <div className="min-h-screen bg-background">
      <Toaster />
      
      {/* Header */}
      <header className="bg-white border-b sticky top-0 z-10" style={{ borderColor: 'rgba(66, 64, 148, 0.2)' }}>
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Building2 className="w-8 h-8" style={{ color: '#424094' }} />
              <div>
                <h1 className="text-xl font-bold">Giga Group</h1>
                <p className="text-sm" style={{ color: '#2699C7' }}>Employee Management System</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-600">View as:</span>
              <Button
                variant={activeTab === 'employee' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setActiveTab('employee')}
              >
                <User className="w-4 h-4 mr-2" />
                Employee
              </Button>
              <Button
                variant={activeTab === 'admin' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setActiveTab('admin')}
              >
                <Shield className="w-4 h-4 mr-2" />
                Admin
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <Tabs value={activeTab} onValueChange={(value: any) => setActiveTab(value)}>
          <TabsContent value="employee" className="mt-0">
            <HomePage
              employeeName={employeeData.name}
              employeeWage={employeeData.wage}
              absentDays={employeeData.absentDays}
              onLeaveRequest={() => setIsLeaveRequestOpen(true)}
              announcements={announcements}
              onAddComment={handleAddComment}
            />
            <EmployeeChat currentUserName={employeeData.name} />
          </TabsContent>

          <TabsContent value="admin" className="mt-0">
            <AdminDashboard
              leaveRequests={leaveRequests}
              onApprove={handleApprove}
              onReject={handleReject}
              announcements={announcements}
              onCreateAnnouncement={() => setIsAnnouncementFormOpen(true)}
            />
          </TabsContent>
        </Tabs>
      </main>

      {/* Leave Request Dialog */}
      <LeaveRequest
        open={isLeaveRequestOpen}
        onClose={() => setIsLeaveRequestOpen(false)}
        onSubmit={handleLeaveRequestSubmit}
        employeeName={employeeData.name}
      />

      {/* Announcement Form Dialog */}
      <AnnouncementForm
        open={isAnnouncementFormOpen}
        onClose={() => setIsAnnouncementFormOpen(false)}
        onSubmit={handleAnnouncementSubmit}
      />
    </div>
  );
}