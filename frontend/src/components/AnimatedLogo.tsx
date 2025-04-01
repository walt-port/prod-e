import React, { useEffect, useRef, useState } from 'react';

const AnimatedLogo: React.FC = () => {
  const [isEgg, setIsEgg] = useState(false);
  const textRef = useRef<HTMLDivElement>(null); // Ref to measure text size
  const [svgSize, setSvgSize] = useState({ width: 0, height: 0 }); // State for SVG dimensions

  const toggleEgg = () => {
    setIsEgg(!isEgg);
  };

  // Effect to measure the text element size after render/update
  useEffect(() => {
    if (textRef.current) {
      const { offsetWidth, offsetHeight } = textRef.current;
      // Restore padding to 12
      const padding = 12;
      setSvgSize({
        // Add extra horizontal padding
        width: offsetWidth + padding * 2 + 8,
        height: offsetHeight + padding * 2, // Keep vertical padding as is
      });
    }
  }, [isEgg]); // Re-measure if text content changes (egg toggle)

  return (
    // Outer container - Keep relative inline-block
    <div className="relative inline-block">
      {/* SVG container - Adjust vertical alignment */}
      <svg
        width={svgSize.width}
        height={svgSize.height}
        className="absolute top-[49%] left-1/2 -translate-x-1/2 -translate-y-[47%]"
      >
        {/* Animated border rectangle - Revert position/size changes */}
        <rect
          x="1" // Revert x
          y="1" // Revert y
          // Revert width/height
          width={svgSize.width > 0 ? svgSize.width - 2 : 0}
          height={svgSize.height > 0 ? svgSize.height - 2 : 0}
          rx="8" // Rounded corners
          fill="none"
          stroke="#e0af68" // Example border color
          strokeWidth="2"
        />
        {/* TODO: Add SVG animation for stroke gradient/rotation */}
      </svg>

      {/* Text element - assign ref, use inline-block for measurement */}
      <div
        ref={textRef}
        className="font-hermit text-[#c0caf5] cursor-pointer inline-block relative z-10" // Added z-10 to be above SVG
        style={{ fontSize: '3.5rem', fontWeight: 'bold' }} // Increased font size
        onClick={toggleEgg}
      >
        <span>prod-</span>
        {/* Egg color from original sketch: #9ece6a (green) */}
        <span style={{ color: isEgg ? '#9ece6a' : 'inherit' }}>{isEgg ? '🥚' : 'e'}</span>
      </div>
    </div>
  );
};

export default AnimatedLogo;
