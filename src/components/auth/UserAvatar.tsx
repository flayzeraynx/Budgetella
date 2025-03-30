import React from 'react';
import { useAuth } from '../../context/AuthContext';

interface UserAvatarProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const UserAvatar: React.FC<UserAvatarProps> = ({ 
  size = 'md',
  className = ''
}) => {
  const { currentUser } = useAuth();
  
  // Size classes
  const sizeClasses = {
    sm: 'w-8 h-8 text-xs',
    md: 'w-10 h-10 text-sm',
    lg: 'w-12 h-12 text-base'
  };
  
  // If no user is signed in, return null
  if (!currentUser) {
    return null;
  }
  
  // Get user's display name or email
  const displayName = currentUser.displayName || currentUser.email || '';
  
  // Get initials from display name
  const getInitials = () => {
    if (!displayName) return '?';
    
    const nameParts = displayName.split(' ');
    if (nameParts.length === 1) {
      return displayName.charAt(0).toUpperCase();
    }
    
    return (nameParts[0].charAt(0) + nameParts[nameParts.length - 1].charAt(0)).toUpperCase();
  };
  
  // Check if user has a photo URL (Google sign-in)
  const hasPhotoUrl = currentUser.photoURL && currentUser.photoURL.startsWith('http');
  
  // Generate a random but consistent color based on the user's ID
  const getBackgroundColor = () => {
    if (!currentUser.uid) return 'bg-primary-500';
    
    const colors = [
      'bg-primary-500',
      'bg-green-500',
      'bg-yellow-500',
      'bg-red-500',
      'bg-purple-500',
      'bg-pink-500',
      'bg-indigo-500',
      'bg-blue-500',
      'bg-teal-500'
    ];
    
    const index = currentUser.uid
      .split('')
      .reduce((acc, char) => acc + char.charCodeAt(0), 0) % colors.length;
    
    return colors[index];
  };
  
  return (
    <div 
      className={`${sizeClasses[size]} rounded-full flex items-center justify-center text-white font-medium ${className} ${hasPhotoUrl ? '' : getBackgroundColor()}`}
    >
      {hasPhotoUrl ? (
        <img 
          src={currentUser.photoURL!} 
          alt={displayName}
          className="w-full h-full rounded-full object-cover"
        />
      ) : (
        getInitials()
      )}
    </div>
  );
};

export default UserAvatar;
