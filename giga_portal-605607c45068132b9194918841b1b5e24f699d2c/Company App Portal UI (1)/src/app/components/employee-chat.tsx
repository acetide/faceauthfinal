import { useState, useRef, useEffect } from 'react';
import { Card } from '@/app/components/ui/card';
import { Button } from '@/app/components/ui/button';
import { Input } from '@/app/components/ui/input';
import { MessageCircle, X, Send, User } from 'lucide-react';

interface Message {
  id: string;
  sender: string;
  text: string;
  timestamp: string;
  isCurrentUser: boolean;
}

interface EmployeeChatProps {
  currentUserName: string;
}

export function EmployeeChat({ currentUserName }: EmployeeChatProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [message, setMessage] = useState('');
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      sender: 'Ahmad Saleh',
      text: 'Hey everyone! Anyone free for lunch today?',
      timestamp: '10:15 AM',
      isCurrentUser: false,
    },
    {
      id: '2',
      sender: 'Robert Sutadi',
      text: 'I am! What time were you thinking?',
      timestamp: '10:17 AM',
      isCurrentUser: false,
    },
    {
      id: '3',
      sender: 'Fitri Sutrisno',
      text: 'Count me in too! 12:30 works for me.',
      timestamp: '10:20 AM',
      isCurrentUser: false,
    },
    {
      id: '4',
      sender: 'Samuel Panggabean',
      text: 'Has anyone seen the new project requirements?',
      timestamp: '10:45 AM',
      isCurrentUser: false,
    },
  ]);
  
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = () => {
    if (message.trim()) {
      const newMessage: Message = {
        id: Date.now().toString(),
        sender: currentUserName,
        text: message,
        timestamp: new Date().toLocaleTimeString('en-US', {
          hour: 'numeric',
          minute: '2-digit',
          hour12: true,
        }),
        isCurrentUser: true,
      };

      setMessages([...messages, newMessage]);
      setMessage('');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  return (
    <>
      {/* Chat Button */}
      {!isOpen && (
        <button
          onClick={() => setIsOpen(true)}
          className="fixed bottom-6 right-6 w-14 h-14 rounded-full shadow-lg flex items-center justify-center transition-transform hover:scale-110 z-50"
          style={{ backgroundColor: '#424094' }}
        >
          <MessageCircle className="w-6 h-6 text-white" />
        </button>
      )}

      {/* Chat Window */}
      {isOpen && (
        <Card className="fixed bottom-6 right-6 w-96 h-[500px] shadow-2xl flex flex-col z-50">
          {/* Header */}
          <div
            className="p-4 rounded-t-lg flex items-center justify-between"
            style={{ backgroundColor: '#424094' }}
          >
            <div className="flex items-center gap-2">
              <MessageCircle className="w-5 h-5 text-white" />
              <h3 className="font-semibold text-white">Employee Chat</h3>
            </div>
            <button
              onClick={() => setIsOpen(false)}
              className="text-white hover:bg-white/20 rounded p-1 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50">
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={`flex ${msg.isCurrentUser ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[75%] rounded-lg p-3 ${
                    msg.isCurrentUser
                      ? 'text-white'
                      : 'bg-white border'
                  }`}
                  style={msg.isCurrentUser ? { backgroundColor: '#2699C7' } : {}}
                >
                  {!msg.isCurrentUser && (
                    <div className="flex items-center gap-2 mb-1">
                      <User className="w-3 h-3" style={{ color: '#424094' }} />
                      <p className="text-xs font-semibold" style={{ color: '#424094' }}>
                        {msg.sender}
                      </p>
                    </div>
                  )}
                  <p className="text-sm">{msg.text}</p>
                  <p
                    className={`text-xs mt-1 ${
                      msg.isCurrentUser ? 'text-white/70' : 'text-gray-500'
                    }`}
                  >
                    {msg.timestamp}
                  </p>
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          {/* Input */}
          <div className="p-4 border-t bg-white rounded-b-lg">
            <div className="flex gap-2">
              <Input
                placeholder="Type a message..."
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                onKeyPress={handleKeyPress}
                className="flex-1"
              />
              <Button
                onClick={handleSendMessage}
                disabled={!message.trim()}
                size="sm"
                style={{ backgroundColor: '#424094' }}
              >
                <Send className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </Card>
      )}
    </>
  );
}