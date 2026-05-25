import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/app/components/ui/dialog';
import { Button } from '@/app/components/ui/button';
import { Label } from '@/app/components/ui/label';
import { Input } from '@/app/components/ui/input';
import { Textarea } from '@/app/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/app/components/ui/select';
import { Megaphone, Image as ImageIcon } from 'lucide-react';

export interface AnnouncementFormData {
  title: string;
  message: string;
  type: 'info' | 'warning' | 'success';
  imageUrl?: string;
}

interface AnnouncementFormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (announcement: AnnouncementFormData) => void;
}

export function AnnouncementForm({ open, onClose, onSubmit }: AnnouncementFormProps) {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [type, setType] = useState<'info' | 'warning' | 'success'>('info');
  const [imageUrl, setImageUrl] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!title || !message) {
      alert('Please fill in title and message');
      return;
    }

    onSubmit({
      title,
      message,
      type,
      imageUrl: imageUrl || undefined,
    });

    // Reset form
    setTitle('');
    setMessage('');
    setType('info');
    setImageUrl('');
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>Create New Announcement</DialogTitle>
          <DialogDescription>
            Create an announcement that will be visible to all employees.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4 mt-4">
          <div className="space-y-2">
            <Label htmlFor="title">Title</Label>
            <Input
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Enter announcement title"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="type">Type</Label>
            <Select value={type} onValueChange={(value: any) => setType(value)}>
              <SelectTrigger id="type">
                <SelectValue placeholder="Select announcement type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="info">Info</SelectItem>
                <SelectItem value="warning">Warning</SelectItem>
                <SelectItem value="success">Success</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="message">Message</Label>
            <Textarea
              id="message"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Enter announcement message..."
              rows={4}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="imageUrl">Image URL (Optional)</Label>
            <div className="flex gap-2">
              <Input
                id="imageUrl"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://example.com/image.jpg"
              />
              <Button type="button" variant="outline" size="icon">
                <ImageIcon className="w-4 h-4" />
              </Button>
            </div>
            <p className="text-xs text-gray-500">
              Paste an image URL or leave empty for text-only announcement
            </p>
          </div>

          {imageUrl && (
            <div className="space-y-2">
              <Label>Image Preview</Label>
              <div className="border rounded-lg overflow-hidden">
                <img
                  src={imageUrl}
                  alt="Preview"
                  className="w-full h-48 object-cover"
                  onError={(e) => {
                    e.currentTarget.src = 'https://via.placeholder.com/400x200?text=Invalid+Image+URL';
                  }}
                />
              </div>
            </div>
          )}

          <div className="flex gap-3 pt-4">
            <Button type="button" variant="outline" onClick={onClose} className="flex-1">
              Cancel
            </Button>
            <Button type="submit" className="flex-1">
              <Megaphone className="w-4 h-4 mr-2" />
              Create Announcement
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
