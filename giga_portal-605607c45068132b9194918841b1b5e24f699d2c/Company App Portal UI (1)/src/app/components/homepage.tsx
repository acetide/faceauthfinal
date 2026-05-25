import { useState, useEffect } from 'react';
import { Card } from '@/app/components/ui/card';
import { Button } from '@/app/components/ui/button';
import { Badge } from '@/app/components/ui/badge';
import { Input } from '@/app/components/ui/input';
import { Clock, LogIn, LogOut, Calendar, Megaphone, MessageCircle, Send, ScanFace, MapPin, CheckCircle2 } from 'lucide-react';

interface HomePageProps {
  employeeName: string;
  employeeWage: string;
  absentDays: number;
  onLeaveRequest: () => void;
  announcements: Announcement[];
  onAddComment: (announcementId: string, comment: string) => void;
}

interface AttendanceRecord {
  clockIn: string | null;
  clockOut: string | null;
  date: string;
}

export interface Comment {
  id: string;
  authorName: string;
  text: string;
  timestamp: string;
}

interface Announcement {
  id: string;
  title: string;
  message: string;
  date: string;
  type: 'info' | 'warning' | 'success';
  imageUrl?: string;
  comments: Comment[];
}

export function HomePage({ employeeName, employeeWage, absentDays, onLeaveRequest, announcements, onAddComment }: HomePageProps) {
  const [attendance, setAttendance] = useState<AttendanceRecord>({
    clockIn: null,
    clockOut: null,
    date: new Date().toLocaleDateString(),
  });
  const [currentTime, setCurrentTime] = useState(new Date().toLocaleTimeString());
  const [commentInputs, setCommentInputs] = useState<{ [key: string]: string }>({});
  const [expandedAnnouncements, setExpandedAnnouncements] = useState<{ [key: string]: boolean }>({});
  const [faceIdVerified, setFaceIdVerified] = useState(false);
  const [locationVerified, setLocationVerified] = useState(false);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  const handleFaceIdVerify = () => {
    // Simulate Face ID verification
    setTimeout(() => {
      setFaceIdVerified(true);
    }, 1000);
  };

  const handleLocationVerify = () => {
    // Simulate location verification
    setTimeout(() => {
      setLocationVerified(true);
    }, 1000);
  };

  const handleClockIn = () => {
    setAttendance({
      ...attendance,
      clockIn: new Date().toLocaleTimeString(),
    });
    // Reset verifications after clocking in
    setFaceIdVerified(false);
    setLocationVerified(false);
  };

  const handleClockOut = () => {
    setAttendance({
      ...attendance,
      clockOut: new Date().toLocaleTimeString(),
    });
  };

  const getBadgeVariant = (type: string) => {
    switch (type) {
      case 'warning':
        return 'destructive';
      case 'success':
        return 'default';
      default:
        return 'secondary';
    }
  };

  const handleAddComment = (announcementId: string) => {
    const comment = commentInputs[announcementId]?.trim();
    if (comment) {
      onAddComment(announcementId, comment);
      setCommentInputs({ ...commentInputs, [announcementId]: '' });
    }
  };

  const toggleComments = (announcementId: string) => {
    setExpandedAnnouncements({
      ...expandedAnnouncements,
      [announcementId]: !expandedAnnouncements[announcementId],
    });
  };

  return (
    <div className="space-y-6">
      {/* Announcements Section */}
      <Card className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <Megaphone className="w-5 h-5" />
          <h2 className="text-xl font-semibold">Announcements</h2>
        </div>
        <div className="space-y-3">
          {announcements.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <Megaphone className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>No announcements yet</p>
            </div>
          ) : (
            announcements.map((announcement) => (
              <div
                key={announcement.id}
                className="border rounded-lg overflow-hidden hover:shadow-md transition-shadow"
              >
                <div className="p-4">
                  <div className="flex items-start justify-between gap-3 mb-3">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-medium">{announcement.title}</h3>
                        <Badge variant={getBadgeVariant(announcement.type)}>
                          {announcement.type}
                        </Badge>
                      </div>
                      <p className="text-sm text-gray-600">{announcement.message}</p>
                      <p className="text-xs text-gray-400 mt-2">{announcement.date}</p>
                    </div>
                  </div>

                  {/* Image Display */}
                  {announcement.imageUrl && (
                    <div className="mb-3 rounded-lg overflow-hidden">
                      <img
                        src={announcement.imageUrl}
                        alt={announcement.title}
                        className="w-full h-64 object-cover"
                        onError={(e) => {
                          e.currentTarget.style.display = 'none';
                        }}
                      />
                    </div>
                  )}

                  {/* Comments Section */}
                  <div className="border-t pt-3 mt-3">
                    <button
                      onClick={() => toggleComments(announcement.id)}
                      className="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 mb-2"
                    >
                      <MessageCircle className="w-4 h-4" />
                      <span>
                        {announcement.comments.length} Comment
                        {announcement.comments.length !== 1 ? 's' : ''}
                      </span>
                    </button>

                    {expandedAnnouncements[announcement.id] && (
                      <div className="space-y-3 mt-3">
                        {/* Display Comments */}
                        {announcement.comments.length > 0 && (
                          <div className="space-y-2 mb-3">
                            {announcement.comments.map((comment) => (
                              <div
                                key={comment.id}
                                className="bg-gray-50 p-3 rounded-lg"
                              >
                                <div className="flex items-center justify-between mb-1">
                                  <span className="text-sm font-medium">
                                    {comment.authorName}
                                  </span>
                                  <span className="text-xs text-gray-500">
                                    {comment.timestamp}
                                  </span>
                                </div>
                                <p className="text-sm text-gray-700">{comment.text}</p>
                              </div>
                            ))}
                          </div>
                        )}

                        {/* Add Comment Input */}
                        <div className="flex gap-2">
                          <Input
                            placeholder="Write a comment..."
                            value={commentInputs[announcement.id] || ''}
                            onChange={(e) =>
                              setCommentInputs({
                                ...commentInputs,
                                [announcement.id]: e.target.value,
                              })
                            }
                            onKeyPress={(e) => {
                              if (e.key === 'Enter') {
                                handleAddComment(announcement.id);
                              }
                            }}
                          />
                          <Button
                            size="sm"
                            onClick={() => handleAddComment(announcement.id)}
                            disabled={!commentInputs[announcement.id]?.trim()}
                          >
                            <Send className="w-4 h-4" />
                          </Button>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </Card>

      {/* Employee Info Card */}
      <Card className="p-6">
        <h2 className="text-xl font-semibold mb-4">Employee Information</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="p-4 rounded-lg" style={{ backgroundColor: '#90CFE0' }}>
            <p className="text-sm text-gray-800">Employee Name</p>
            <p className="text-lg font-semibold">{employeeName}</p>
          </div>
          <div className="p-4 rounded-lg" style={{ backgroundColor: '#2699C7' }}>
            <p className="text-sm text-white">Monthly Wage</p>
            <p className="text-lg font-semibold text-white">{employeeWage}</p>
          </div>
          <div className="p-4 rounded-lg" style={{ backgroundColor: '#D5E2E6' }}>
            <p className="text-sm text-gray-800">Absent Days (This Month)</p>
            <p className="text-lg font-semibold">{absentDays} days</p>
          </div>
        </div>
      </Card>

      {/* Attendance Card */}
      <Card className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <Clock className="w-5 h-5" />
          <h2 className="text-xl font-semibold">Attendance</h2>
        </div>
        
        <div className="mb-6 p-4 bg-gray-50 rounded-lg">
          <p className="text-2xl font-mono text-center">{currentTime}</p>
          <p className="text-sm text-gray-600 text-center mt-1">{attendance.date}</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <div className="p-4 border rounded-lg">
            <div className="flex items-center gap-2 mb-2">
              <LogIn className="w-4 h-4 text-green-600" />
              <p className="text-sm font-medium">Clock In</p>
            </div>
            <p className="text-xl font-semibold">
              {attendance.clockIn || '--:--:--'}
            </p>
          </div>
          <div className="p-4 border rounded-lg">
            <div className="flex items-center gap-2 mb-2">
              <LogOut className="w-4 h-4 text-red-600" />
              <p className="text-sm font-medium">Clock Out</p>
            </div>
            <p className="text-xl font-semibold">
              {attendance.clockOut || '--:--:--'}
            </p>
          </div>
        </div>

        {/* Verification Buttons */}
        {attendance.clockIn === null && (
          <div className="mb-4 p-4 rounded-lg" style={{ backgroundColor: '#D5E2E6' }}>
            <p className="text-sm font-medium mb-3">Verify Identity & Location Before Clock In</p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <Button
                onClick={handleFaceIdVerify}
                disabled={faceIdVerified}
                variant={faceIdVerified ? 'default' : 'outline'}
                className="w-full"
                style={
                  faceIdVerified
                    ? { backgroundColor: '#2699C7', color: 'white' }
                    : {}
                }
              >
                {faceIdVerified ? (
                  <>
                    <CheckCircle2 className="w-4 h-4 mr-2" />
                    Face ID Verified
                  </>
                ) : (
                  <>
                    <ScanFace className="w-4 h-4 mr-2" />
                    Verify Face ID
                  </>
                )}
              </Button>
              <Button
                onClick={handleLocationVerify}
                disabled={locationVerified}
                variant={locationVerified ? 'default' : 'outline'}
                className="w-full"
                style={
                  locationVerified
                    ? { backgroundColor: '#2699C7', color: 'white' }
                    : {}
                }
              >
                {locationVerified ? (
                  <>
                    <CheckCircle2 className="w-4 h-4 mr-2" />
                    Location Verified
                  </>
                ) : (
                  <>
                    <MapPin className="w-4 h-4 mr-2" />
                    Verify Location
                  </>
                )}
              </Button>
            </div>
          </div>
        )}

        <div className="flex gap-3">
          <Button
            onClick={handleClockIn}
            disabled={attendance.clockIn !== null || !faceIdVerified || !locationVerified}
            className="flex-1"
            variant="default"
            style={
              faceIdVerified && locationVerified && attendance.clockIn === null
                ? { backgroundColor: '#424094' }
                : {}
            }
          >
            <LogIn className="w-4 h-4 mr-2" />
            Clock In
          </Button>
          <Button
            onClick={handleClockOut}
            disabled={attendance.clockIn === null || attendance.clockOut !== null}
            className="flex-1"
            variant="outline"
          >
            <LogOut className="w-4 h-4 mr-2" />
            Clock Out
          </Button>
        </div>
      </Card>

      {/* Leave Request Button */}
      <Card className="p-6">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-semibold mb-1">Need Time Off?</h3>
            <p className="text-sm text-gray-600">Submit a leave request for approval</p>
          </div>
          <Button onClick={onLeaveRequest}>
            <Calendar className="w-4 h-4 mr-2" />
            Request Leave
          </Button>
        </div>
      </Card>
    </div>
  );
}