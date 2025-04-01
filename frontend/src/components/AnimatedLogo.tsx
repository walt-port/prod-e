import React, { useState } from 'react';

const AnimatedLogo: React.FC = () => {
  const [isEgg, setIsEgg] = useState(false);

  const toggleEgg = () => {
    setIsEgg(!isEgg);
  };

  // TODO: Add CSS/Tailwind for the rotating gradient border animation
  return (
    <div
      className="h-full flex items-center justify-center relative" // Added relative for pseudo-element positioning later
    >
      <div
        className="logo text-4xl font-hermit text-[#c0caf5] cursor-pointer" // Added class "logo" for custom CSS target
        onClick={toggleEgg}
      >
        <span>prod-</span>
        {/* Egg color from original sketch: #9ece6a (green) */}
        <span style={{ color: isEgg ? '#9ece6a' : 'inherit' }}>{isEgg ? '🥚' : 'e'}</span>
      </div>
      {/* We will add the animation styles via index.css targeting the .logo class */}
    </div>
  );
};

export default AnimatedLogo;
